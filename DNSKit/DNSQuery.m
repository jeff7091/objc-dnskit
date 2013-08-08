#import "DNSQuery.h"
#include "dns_util.h"

@interface DNSQuery ()
  @property(nonatomic,copy) DNSQueryReplyBlock block;
  // GCD props.
  @property(nonatomic) dispatch_source_t source;
  @property(nonatomic) dispatch_source_t timer;
  // DNS API props.
  @property(nonatomic) DNSServiceRef sdRef;
  @property(nonatomic) BOOL sdRefIsActive;
  // Response-building props.
  @property(nonatomic,retain) NSMutableArray *buildRawRecords;
  @property(nonatomic,retain) NSMutableArray *buildRecords;
  @property(nonatomic,retain) DNSResponse *buildResponse;
  -(void)clearBuild;
  -(void)goInert;
  -(void)finish;
  -(void)reportErrorCode:(NSInteger)code;
@end

static void
dns_query_record_reply_handler(DNSServiceRef sdRef,
			       DNSServiceFlags flags,
			       uint32_t interfaceIndex,
			       DNSServiceErrorType errorCode,
			       const char *c_fullname,
			       uint16_t rrtype,
			       uint16_t rrclass,
			       uint16_t rdlen,
			       const void *rdata,
			       uint32_t ttl,
			       void *context) {
  DNSQuery *query = (id)context;
  DNSResponse *response = query.buildResponse;
  if (kDNSServiceErr_NoError != errorCode) {
    [query reportErrorCode:errorCode];
    return;
  }
  NSString *fullname = [NSString stringWithCString:c_fullname encoding:NSUTF8StringEncoding];
  if (response.fullname) {
    NSCAssert([response.fullname isEqualToString:fullname], @"Response with different fullname.");
    NSCAssert(rrtype == response.rrType, @"Response with different RR type.");
    NSCAssert(rrclass == response.rrClass, @"Response with different RR class.");
    response.ttl = MIN(ttl, response.ttl);
  } else {
    query.buildResponse.fullname = fullname;
    query.buildResponse.rrType = rrtype;
    query.buildResponse.rrClass = rrclass;
    query.buildResponse.ttl = ttl;
  }
  // Pre-pending kludge idea taken from Apple:
  // http://developer.apple.com/library/mac/#samplecode/SRVResolver/Introduction/Intro.html.
  // Note that the Apple example will croak on munged packets, calling free() on a NSMutableData buffer.
  // Pretty infuriating when you just know that the preamble is probably preceding rdata in the buffer!
  uint8_t net8 = 0;
  NSMutableData *raw = [NSMutableData dataWithBytes:&net8 length:1];
  uint16_t net16;
  uint32_t net32;
  net16 = htons(rrtype); [raw appendBytes:&net16 length:sizeof(uint16_t)];
  net16 = htons(rrclass); [raw appendBytes:&net16 length:sizeof(uint16_t)];
  net32 = htonl(ttl); [raw appendBytes:&net32 length:sizeof(uint32_t)];
  net16 = htons(rdlen); [raw appendBytes:&net16 length:sizeof(uint16_t)];
  [raw appendBytes:rdata length:rdlen];
  DNSRecord *record = [DNSRecord recordWithData:raw];
  if (nil == record) {
    [query reportErrorCode:kDNSServiceErr_Unknown];
    return;
  }
  [query.buildRecords addObject:record];
  [query.buildRawRecords addObject:[NSData dataWithBytes:rdata length:rdlen]];

  // Check the more flag. If more records are on the way, then don't deallocate/callback yet.
  if (0 == (kDNSServiceFlagsMoreComing & flags)) {
    [query finish];
  }
}

@implementation DNSQuery

- (id)init {
  if (self = [super init]) {
    self.rrType = kDNSServiceType_A;
    self.rrClass = kDNSServiceClass_IN;
    self.timeout = 5; // Seconds.
    if (nil == (self.buildResponse = [[DNSResponse alloc] init]) ||
	nil == (self.buildRawRecords = [[NSMutableArray alloc] init]) ||
	nil == (self.buildRecords = [[NSMutableArray alloc] init])) {
      [self autorelease];
      return nil;
    }
  }
  return self;
}

- (BOOL)searchWithName:(NSString*)name 
		 block:(DNSQueryReplyBlock)block {
  if (self.sdRefIsActive) {
    return NO;
  }
  self.block = block;
  DNSServiceErrorType error = DNSServiceQueryRecord(&_sdRef, 0, 0, [name cStringUsingEncoding:NSUTF8StringEncoding],
						    self.rrType, self.rrClass, 
						    dns_query_record_reply_handler, (void*)self);
  if (kDNSServiceErr_NoError != error) {
    return NO;
  }

  self.sdRefIsActive = YES;
  int fd = DNSServiceRefSockFD(self.sdRef);
  dispatch_queue_t queue = ([NSThread isMainThread])? dispatch_get_main_queue() : 
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

  self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
  if (NULL == self.timer) {
    [self goInert];
    return NO;
  }
  dispatch_source_set_timer(self.timer, dispatch_time(DISPATCH_TIME_NOW, self.timeout * NSEC_PER_SEC),
			    self.timeout * NSEC_PER_SEC, NSEC_PER_SEC);
  dispatch_source_set_event_handler(self.timer, ^{
      [self finish];
    });
  dispatch_resume(self.timer);
  self.source = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, fd, 0, queue);
  if (NULL == self.source) {
    [self goInert];
    return NO;
  }
  dispatch_source_set_registration_handler(self.source, ^{
      // Chicken-egg issue between sdRef's socket and making the query, possibly generating 
      // an event before the handler is active with GCD. Handler will be active once we return.
      fd_set fds;
      struct timeval nonblock = {0, 0};
      FD_ZERO(&fds);
      FD_SET(fd, &fds);
      if (0 < select(fd+1, &fds, NULL, NULL, &nonblock)) {
	DNSServiceErrorType error_type = DNSServiceProcessResult(self.sdRef);
	if (error_type) {
	  [self reportErrorCode:error_type];
	}
      }
    });
  dispatch_source_set_event_handler(self.source, ^{
      DNSServiceErrorType error_type = DNSServiceProcessResult(self.sdRef);
      if (error_type) {
	[self reportErrorCode:error_type];
      }
    });
  dispatch_resume(self.source);
  return YES;
}

- (void)dealloc {
  [self goInert];
  [self clearBuild];
  self.block = nil;
  [super dealloc];
}

// Class extension (private) methods below this line.

- (void)reportErrorCode:(NSInteger)code {
  self.buildResponse.fullname = nil;
  self.buildResponse.rawRecords = nil;
  self.buildResponse.records = nil;
  self.buildResponse.error = [NSError errorWithDomain:@"DNSKit" 
						 code:code
					     userInfo:nil];
  [self finish];
}

- (void)goInert {
  if (self.sdRefIsActive) {
    // Turn off DNS query.
    DNSServiceRefDeallocate(self.sdRef);
    bzero(&_sdRef, sizeof(DNSServiceRef));
    self.sdRefIsActive = NO;
  }
  // Turn off GCD sources.
  if (self.source) {
    dispatch_source_set_event_handler_f(self.source, NULL);
    dispatch_source_cancel(self.source);
    dispatch_release(self.source);
    self.source = nil;
  }
  if (self.timer) {
    dispatch_source_set_event_handler_f(self.timer, NULL);
    dispatch_source_cancel(self.timer);
    dispatch_release(self.timer);
    self.timer = nil;
  }
}

- (void)clearBuild {
  self.buildRawRecords = nil;
  self.buildRecords = nil;
  self.buildResponse = nil;
}

- (void)finish {
  [self goInert];
  // Finish building response object.
  self.buildResponse.rawRecords = self.buildRawRecords;
  self.buildResponse.records = self.buildRecords;
  self.block(self.buildResponse); // Deliver response.
  [self clearBuild];  // Release *after* calling block.
}
@end
