#include <dns_sd.h>
#import <Foundation/Foundation.h>
#import "DNSResponse.h"

typedef void (^DNSQueryReplyBlock)(DNSResponse *response);

@interface DNSQuery : NSObject
  @property(nonatomic) uint16_t rrType;
  @property(nonatomic) uint16_t rrClass;
  @property(nonatomic) uint16_t timeout;

  -(BOOL)searchWithName:(NSString*)name block:(DNSQueryReplyBlock)block;
  -(void)cancel;
@end
