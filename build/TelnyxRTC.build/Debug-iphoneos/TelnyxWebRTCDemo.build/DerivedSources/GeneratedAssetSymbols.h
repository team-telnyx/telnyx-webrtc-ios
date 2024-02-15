#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "ic-call" asset catalog image resource.
static NSString * const ACImageNameIcCall AC_SWIFT_PRIVATE = @"ic-call";

/// The "ic-hangup" asset catalog image resource.
static NSString * const ACImageNameIcHangup AC_SWIFT_PRIVATE = @"ic-hangup";

/// The "logo" asset catalog image resource.
static NSString * const ACImageNameLogo AC_SWIFT_PRIVATE = @"logo";

/// The "logo-white" asset catalog image resource.
static NSString * const ACImageNameLogoWhite AC_SWIFT_PRIVATE = @"logo-white";

#undef AC_SWIFT_PRIVATE