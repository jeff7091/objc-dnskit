#include <dns_sd.h>
#include "dns_util.h"
#import "DNSResponse.h"

@implementation DNSResponse
@end

@interface DNSSRVRecord ()
  +(DNSSRVRecord*)recordWithStruct:(dns_resource_record_t*)c_record;
@end

@implementation DNSRecord
+ (DNSRecord*)recordWithData:(NSData*)data {
  dns_resource_record_t *c_record = dns_parse_resource_record([data bytes], [data length]);
  if (NULL == c_record) {
    return nil;
  }
  
  switch (c_record->dnstype) {
  case kDNSServiceType_SRV:
    return [DNSSRVRecord recordWithStruct:c_record];

  default:
    // Support of new record types left to those who need said support.
    return nil;
  }
}
@end

@implementation DNSSRVRecord
+ (DNSSRVRecord*)recordWithStruct:(dns_resource_record_t*)c_record {
  DNSSRVRecord *retval = [[DNSSRVRecord alloc] init];
  retval.priority = c_record->data.SRV->priority;
  retval.weight = c_record->data.SRV->weight;
  retval.port = c_record->data.SRV->port;
  retval.target = [NSString stringWithCString:c_record->data.SRV->target encoding:NSUTF8StringEncoding];
  return retval;
}
@end
