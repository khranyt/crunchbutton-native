//
//  BPCard.m
//  Balanced iOS
//
//  Created by Ben Mills on 3/9/13.
//

#import "BPCard.h"

@implementation BPCard
@synthesize errors;

- (id)initWithNumber:(NSString *)cardNumber
     expirationMonth:(NSUInteger)expirationMonth
      expirationYear:(NSUInteger)expirationYear
{
    return [self initWithNumber:cardNumber expirationMonth:expirationMonth expirationYear:expirationYear optionalFields:nil];
}

- (id)initWithNumber:(NSString *)cardNumber
     expirationMonth:(NSUInteger)expirationMonth
      expirationYear:(NSUInteger)expirationYear
      optionalFields:(NSDictionary *)optionalFields
{
    self = [super init];
    
    if (self) {
        [self setNumber:[cardNumber stringByReplacingOccurrencesOfString:@"\\D"
                                                       withString:@""
                                                          options:NSRegularExpressionSearch
                                                            range:NSMakeRange(0, cardNumber.length)]];
        [self setExpirationMonth:expirationMonth];
        [self setExpirationYear:expirationYear];
        [self setOptionalFields:[NSDictionary dictionaryWithDictionary:optionalFields]];
        self.errors = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (BOOL)getNumberValid {
    if (self.number == nil) { return false; }
    if ([self.number length] < 12) { return false; }
    
    BOOL odd = true;
    int total = 0;
    
    for (int i = self.number.length - 1; i >= 0; i--) {
        int value = [[self.number substringWithRange:NSMakeRange(i, 1)] intValue];
        total += (odd = !odd) ? 2 * value - (value > 4 ? 9 : 0) : value;
    }

    return (total % 10) == 0;
}

- (BPCardSecurityCodeCheck)getSecurityCodeCheck {
    if (self.type == BPCardTypeUnknown) { return BPCardSecurityCodeCheckUnknown; }
    if (self.optionalFields == nil) { return BPCardSecurityCodeCheckUnknown; }
    if ([self.optionalFields valueForKey:BPCardOptionalParamSecurityCodeKey] != nil) {
        NSString *security_code = [[self.optionalFields valueForKey:BPCardOptionalParamSecurityCodeKey]
                                    stringByReplacingOccurrencesOfString:@"\\D"
                                                              withString:@""
                                                                 options:NSRegularExpressionSearch
                                                                   range:NSMakeRange(0, [[self.optionalFields valueForKey:BPCardOptionalParamSecurityCodeKey] length])];
        NSUInteger requiredLength = (self.type==BPCardTypeAmericanExpress) ? 4 : 3;
        if ([security_code length] == requiredLength) {
            return BPCardSecurityCodeCheckPassed;
        }
        else {
            return BPCardSecurityCodeCheckFailed;
        }
    }

    return BPCardSecurityCodeCheckUnknown;
}

- (BOOL)getExpired {
    if (self.expirationMonth > 12 || self.expirationYear < 1) { return false; }
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
    NSInteger currentMonth = [components month];
    NSInteger currentYear = [components year];
    
    return currentYear > self.expirationYear || (currentYear == self.expirationYear && currentMonth >= self.expirationMonth);
}

- (BOOL)getValid {
    BOOL valid = true;
    
    if (!self.numberValid) {
        [errors addObject:@"Card number is not valid"];
        valid = false;
    }
    
    if (self.expired) {
        [errors addObject:@"Card is expired"];
        valid = false;
    }
    
    return valid;
}

- (BPCardType)getType
{
    int digits = [[self.number substringWithRange:NSMakeRange(0, 2)] integerValue];
    
    if (digits >= 40 && digits <= 49) {
        return BPCardTypeVisa;
    }
    else if (digits >= 50 && digits <= 59) {
        return BPCardTypeMastercard;
    }
    else if (digits == 60 || digits == 62 || digits == 64 || digits == 65) {
        return BPCardTypeDiscover;
    }
    else if (digits == 34 || digits == 37) {
        return BPCardTypeAmericanExpress;
    }
    else {
        return BPCardTypeUnknown;
    }
}

@end
