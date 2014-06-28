
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
  @property(nonatomic) NSUInteger priority;
  @property(nonatomic) NSUInteger weight;
  @property(nonatomic) NSUInteger port;
  @property(nonatomic,retain) NSString *target;
@end

@interface DNSARecord     : DNSRecord
  @property(nonatomic,retain) NSString *address;
@end

@interface DNSLOCRecord   : DNSRecord
  @property(nonatomic) NSUInteger version;
  @property(nonatomic) NSUInteger size;
  @property(nonatomic) NSUInteger horizontal_precision;
  @property(nonatomic) NSUInteger vertical_precision;
  @property(nonatomic) NSUInteger latitude;
  @property(nonatomic) NSUInteger longitude;
  @property(nonatomic) NSUInteger altitude;
@end

@interface DNSMXRecord    : DNSRecord
  @property(nonatomic) NSUInteger preference;
  @property(nonatomic,retain) NSString *name;
@end

@interface DNSSOARecord   : DNSRecord
  @property(nonatomic,retain) NSString *mname;
  @property(nonatomic,retain) NSString *rname;
  @property(nonatomic) NSUInteger serial;
  @property(nonatomic) NSUInteger refresh;
  @property(nonatomic) NSUInteger retry;
  @property(nonatomic) NSUInteger expire;
  @property(nonatomic) NSUInteger minimum;
@end

@interface DNSTXTRecord   : DNSRecord
  @property(nonatomic,retain) NSArray *strings;
@end

@interface DNSnameRecord  : DNSRecord
  @property(nonatomic,retain) NSString *name;
@end
@interface DNSCNAMERecord : DNSnameRecord
@end
@interface DNSMBRecord    : DNSnameRecord
@end
@interface DNSMGRecord    : DNSnameRecord
@end
@interface DNSMRRecord    : DNSnameRecord
@end
@interface DNSNSRecord    : DNSnameRecord
@end
@interface DNSPTRRecord   : DNSnameRecord
@end

@interface DNSAAAARecord  : DNSRecord
  @property(nonatomic,retain) NSString *address;
@end

@interface DNSNULLRecord  : DNSRecord
  @property(nonatomic,retain) NSData *octets;
@end
