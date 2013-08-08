
@interface DNSResponse : NSObject
  @property(nonatomic,retain) NSString *fullname;
  @property(nonatomic) uint16_t rrType;
  @property(nonatomic) uint16_t rrClass;
  @property(nonatomic) uint32_t ttl;
  @property(nonatomic,retain) NSError *error;
  @property(nonatomic,retain) NSArray *rawRecords;
  @property(nonatomic,retain) NSArray *records;
@end

@interface DNSRecord : NSObject
  +(DNSRecord*)recordWithData:(NSData*)data;
@end

@interface DNSSRVRecord : DNSRecord
  @property(nonatomic) NSInteger priority;
  @property(nonatomic) NSInteger weight;
  @property(nonatomic) NSInteger port;
  @property(nonatomic,retain) NSString *target;
@end
