#include <dns_sd.h>
#include "dns_util.h"
#import "DNSResponse.h"

@implementation DNSResponse
@end

@interface DNSSRVRecord ()
  +(DNSSRVRecord*)recordWithStruct:(dns_resource_record_t*)c_record;
@end

@interface DNSARecord ()
  +(DNSARecord*)recordWithStruct:(dns_resource_record_t*)c_record;
@end

@interface DNSLOCRecord ()
  +(DNSLOCRecord*)recordWithStruct:(dns_resource_record_t*)c_record;
@end

@interface DNSMXRecord ()
  +(DNSMXRecord*)recordWithStruct:(dns_resource_record_t*)c_record;
@end

@interface DNSSOARecord ()
  +(DNSSOARecord*)recordWithStruct:(dns_resource_record_t*)c_record;
@end

@interface DNSTXTRecord ()
  +(DNSTXTRecord*)recordWithStruct:(dns_resource_record_t*)c_record;
@end

@interface DNSCNAMERecord ()
  +(DNSCNAMERecord*)recordWithStruct:(dns_resource_record_t*)c_record;
@end

@interface DNSMBRecord ()
  +(DNSMBRecord*)recordWithStruct:(dns_resource_record_t*)c_record;
@end

@interface DNSMGRecord ()
  +(DNSMGRecord*)recordWithStruct:(dns_resource_record_t*)c_record;
@end

@interface DNSMRRecord ()
  +(DNSMRRecord*)recordWithStruct:(dns_resource_record_t*)c_record;
@end

@interface DNSNSRecord ()
  +(DNSNSRecord*)recordWithStruct:(dns_resource_record_t*)c_record;
@end

@interface DNSPTRRecord ()
  +(DNSPTRRecord*)recordWithStruct:(dns_resource_record_t*)c_record;
@end

@interface DNSAAAARecord ()
  +(DNSAAAARecord*)recordWithStruct:(dns_resource_record_t*)c_record;
@end

@interface DNSNULLRecord ()
  +(DNSNULLRecord*)recordWithStruct:(dns_resource_record_t*)c_record;
@end


@implementation DNSRecord
+ (DNSRecord*)recordWithData:(NSData*)data {
  dns_resource_record_t *c_record = dns_parse_resource_record([data bytes], [data length]);
  if (NULL == c_record) {
    return nil;
  }
  
  switch (c_record->dnstype) {
  case kDNSServiceType_SRV:   return [DNSSRVRecord recordWithStruct:c_record];
  case kDNSServiceType_A:     return [DNSARecord recordWithStruct:c_record];
  case kDNSServiceType_NS:    return [DNSNSRecord recordWithStruct:c_record];
  case kDNSServiceType_CNAME: return [DNSCNAMERecord recordWithStruct:c_record];
  case kDNSServiceType_SOA:   return [DNSSOARecord recordWithStruct:c_record];
  case kDNSServiceType_MB:    return [DNSMBRecord recordWithStruct:c_record];
  case kDNSServiceType_MG:    return [DNSMGRecord recordWithStruct:c_record];
  case kDNSServiceType_MR:    return [DNSMRRecord recordWithStruct:c_record];
  case kDNSServiceType_NULL:  return [DNSNULLRecord recordWithStruct:c_record];
  case kDNSServiceType_PTR:   return [DNSPTRRecord recordWithStruct:c_record];
  case kDNSServiceType_MX:    return [DNSMXRecord recordWithStruct:c_record];
  case kDNSServiceType_TXT:   return [DNSTXTRecord recordWithStruct:c_record];
  case kDNSServiceType_AAAA:  return [DNSAAAARecord recordWithStruct:c_record];
  case kDNSServiceType_LOC:   return [DNSLOCRecord recordWithStruct:c_record];

  default:
    // Support of new record types left to those who need said support.
    NSLog(@"please add support for record type %d", c_record->dnstype);
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

@implementation DNSARecord
+ (DNSARecord*)recordWithStruct:(dns_resource_record_t*)c_record {
  char ipaddr[INET_ADDRSTRLEN];
  dns_address_record_t *A = c_record->data.A;
  if (!inet_ntop(AF_INET, &A->addr, ipaddr, sizeof ipaddr)) return nil;
  DNSARecord *retval = [[DNSARecord alloc] init];
  retval.address = [NSString stringWithFormat:@"%s", ipaddr];
  return retval;
}
@end

@implementation DNSLOCRecord
+(DNSLOCRecord*)recordWithStruct:(dns_resource_record_t*)c_record {
  dns_LOC_record_t *LOC = c_record->data.LOC;
  DNSLOCRecord*retval = [[DNSLOCRecord alloc] init];
  retval.version = LOC->version;
  retval.size = LOC->size;
  retval.horizontal_precision = LOC->horizontal_precision;
  retval.vertical_precision = LOC->vertical_precision;
  retval.latitude = LOC->latitude;
  retval.longitude = LOC->longitude;
  retval.altitude = LOC->altitude;
  return retval;
}
@end

@implementation DNSMXRecord
+(DNSMXRecord*)recordWithStruct:(dns_resource_record_t*)c_record {
  dns_MX_record_t *MX = c_record->data.MX;
  DNSMXRecord *retval = [[DNSMXRecord alloc] init];
  retval.preference = MX->preference;
  retval.name = [NSString stringWithCString:MX->name encoding:NSUTF8StringEncoding];
  return retval;
}
@end

@implementation DNSSOARecord
+(DNSSOARecord*)recordWithStruct:(dns_resource_record_t*)c_record {
  dns_SOA_record_t *SOA = c_record->data.SOA;
  DNSSOARecord *retval = [[DNSSOARecord alloc] init];
  retval.mname = [NSString stringWithCString:SOA->mname encoding:NSUTF8StringEncoding];
  retval.rname = [NSString stringWithCString:SOA->rname encoding:NSUTF8StringEncoding];
  retval.serial = SOA->serial;
  retval.refresh = SOA->refresh;
  retval.retry = SOA->retry;
  retval.expire = SOA->expire;
  retval.minimum = SOA->minimum;
  return retval;
}
@end

@implementation DNSTXTRecord
+(DNSTXTRecord*)recordWithStruct:(dns_resource_record_t*)c_record {
  dns_TXT_record_t *TXT = c_record->data.TXT;
  NSMutableArray *strings = [[NSMutableArray alloc] initWithCapacity:TXT->string_count];
  NSInteger i;
  char **sp;
  for (i = 0, sp = TXT->strings; i < TXT->string_count; i++, sp++) {
    [strings addObject:[NSString stringWithCString:*sp encoding:NSUTF8StringEncoding]];
  }
  DNSTXTRecord *retval = [[DNSTXTRecord alloc] init];
  retval.strings = [[NSArray alloc] initWithArray:strings];
  return retval;
}
@end

@implementation DNSnameRecord
-(DNSnameRecord*)initWithName:(char *)name {
  if (self = [super init]) {
    self.name = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
  }
  return self;
}
@end

@implementation DNSCNAMERecord
+(DNSCNAMERecord*)recordWithStruct:(dns_resource_record_t*)c_record {
  return [[DNSCNAMERecord alloc] initWithName:c_record->data.CNAME->name];
}
@end

@implementation DNSMBRecord
+(DNSMBRecord*)recordWithStruct:(dns_resource_record_t*)c_record {
  return [[DNSMBRecord alloc] initWithName:c_record->data.MB->name];
}
@end

@implementation DNSMGRecord
+(DNSMGRecord*)recordWithStruct:(dns_resource_record_t*)c_record {
  return [[DNSMGRecord alloc] initWithName:c_record->data.MG->name];
}
@end

@implementation DNSMRRecord
+(DNSMRRecord*)recordWithStruct:(dns_resource_record_t*)c_record {
  return [[DNSMRRecord alloc] initWithName:c_record->data.MR->name];
}
@end

@implementation DNSNSRecord
+(DNSNSRecord*)recordWithStruct:(dns_resource_record_t*)c_record {
  return [[DNSNSRecord alloc] initWithName:c_record->data.NS->name];
}
@end

@implementation DNSPTRRecord
+(DNSPTRRecord*)recordWithStruct:(dns_resource_record_t*)c_record {
  return [[DNSPTRRecord alloc] initWithName:c_record->data.PTR->name];
}
@end

@implementation DNSAAAARecord
+(DNSAAAARecord*)recordWithStruct:(dns_resource_record_t*)c_record {
  char ipaddr[INET6_ADDRSTRLEN];
  dns_in6_address_record_t *AAAA = c_record->data.AAAA;
  if (!inet_ntop(AF_INET6, &AAAA->addr, ipaddr, sizeof ipaddr)) return nil;
  DNSAAAARecord *retval = [[DNSAAAARecord alloc] init];
  retval.address = [NSString stringWithFormat:@"%s", ipaddr];
  return retval;
}
@end

@implementation DNSNULLRecord
+(DNSNULLRecord*)recordWithStruct:(dns_resource_record_t*)c_record {
  DNSNULLRecord *retval = [[DNSNULLRecord alloc] init];
  retval.octets = [NSData dataWithBytes:c_record->data.DNSNULL->data length:c_record->data.DNSNULL->length];
  return retval;
}
@end
