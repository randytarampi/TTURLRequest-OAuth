#import "TTURLRequest+OAuth.h"
#import "RandomString.h"
#import "OAHMAC_SHA1SignatureProvider.h"
#import "OAPlaintextSignatureProvider.h"

#define kDefaultNonceLength 20

@interface TTURLRequest (OAuth_Private)

+ (NSString *)nonce:(int)length;

+ (NSString *)stringForSignatureMethod:(TTURLRequestOAuthSignatureMethod)signatureMethod;

+ (NSString *)signatureBaseStringWithURL:(NSURL*)URL
                              httpMethod:(NSString *)httpMethod
                       requestParameters:(NSDictionary *)requestParameters;

+ (NSString *)signatureStringWithURL:(NSURL*)URL
                         httpMethod:(NSString *)httpMethod
                    signatureMethod:(TTURLRequestOAuthSignatureMethod)signatureMethod
                        accessToken:(NSString *)token
                        tokenSecret:(NSString *)tokenSecret
                     consumerSecret:(NSString *)consumerSecret
                  requestParameters:(NSDictionary *)requestParameters;

+ (NSDictionary *)authDictWithConsumerKey:(NSString *)consumerKey
                           consumerSecret:(NSString *)consumerSecret
                              accessToken:(NSString *)accessToken
                        accessTokenSecret:(NSString *)accessTokenSecret
                          signatureMethod:(TTURLRequestOAuthSignatureMethod)signatureMethod
                                  version:(NSString *)version
                               parameters:(NSDictionary *)parameters
                               httpMethod:(NSString *)httpMethod
                                  urlPath:(NSString *)urlPath;

@end

@implementation TTURLRequest (OAuth)

#pragma mark - Public

/* The original implementation by Colin that doesn't seem to work? */
- (void)oauthifyWithConsumerKey:(NSString *)consumerKey
                consumerSecret:(NSString *)consumerSecret
                   accessToken:(NSString *)accessToken
             accessTokenSecret:(NSString *)accessTokenSecret
               signatureMethod:(TTURLRequestOAuthSignatureMethod)signatureMethod
                       version:(NSString *)version {

    NSMutableDictionary *HTTPAuthorization = [NSMutableDictionary dictionaryWithCapacity:5];
    if (consumerKey) [HTTPAuthorization setObject:consumerKey forKey:@"oauth_consumer_key"];
    if (accessToken) [HTTPAuthorization setObject:accessToken forKey:@"oauth_token"];
    [HTTPAuthorization setObject:[[TTURLRequest class] stringForSignatureMethod:signatureMethod] forKey:@"oauth_signature_method"];
    [HTTPAuthorization setObject:[NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]] forKey:@"oauth_timestamp"];
    [HTTPAuthorization setObject:[[TTURLRequest class] nonce:kDefaultNonceLength] forKey:@"oauth_nonce"];
    if (version) [HTTPAuthorization setObject:version forKey:@"oauth_version"];

    if (!TTIsStringWithAnyText(self.httpMethod)) self.httpMethod = @"GET";

    [HTTPAuthorization setObject:[[TTURLRequest class] signatureStringWithURL:[NSURL URLWithString:self.urlPath]
                                                                   httpMethod:self.httpMethod
                                                              signatureMethod:signatureMethod
                                                                  accessToken:accessToken
                                                                  tokenSecret:accessTokenSecret
                                                               consumerSecret:consumerSecret
                                                            requestParameters:HTTPAuthorization] forKey:@"oauth_signature"];

    // Doing this inline so this lib doesn't have any dependencies
    NSMutableString *HTTPAuthorizationString = [NSMutableString string];

    int i = 0;
    for (NSString *key in HTTPAuthorization) {
        i++;
        [HTTPAuthorizationString appendFormat:@"%@=%@", key, [HTTPAuthorization objectForKey:key]];
        if (i < [[HTTPAuthorization allKeys] count]) [HTTPAuthorizationString appendString:@"&"];
    }

    [self.headers setObject:HTTPAuthorizationString forKey:@"Authorization"];
}

/* My own re-implementation */
- (void)oAuthifyHeaderWithConsumerKey:(NSString *)consumerKey
                       consumerSecret:(NSString *)consumerSecret
                          accessToken:(NSString *)accessToken
                    accessTokenSecret:(NSString *)accessTokenSecret
                      signatureMethod:(TTURLRequestOAuthSignatureMethod)signatureMethod
                              version:(NSString *)version {

    if (!TTIsStringWithAnyText(self.httpMethod)) self.httpMethod = @"GET";

    NSDictionary *HTTPAuthorization = [[self class] authDictWithConsumerKey:consumerKey
                                                           consumerSecret:consumerSecret
                                                              accessToken:accessToken
                                                        accessTokenSecret:accessTokenSecret
                                                          signatureMethod:signatureMethod
                                                                  version:version
                                                               parameters:self.parameters
                                                               httpMethod:self.httpMethod
                                                                  urlPath:self.urlPath];

    // Doing this inline so this lib doesn't have any dependencies
    NSMutableString *HTTPAuthorizationString = [NSMutableString stringWithString:@"OAuth "];

    int i = 0;
    for (NSString *key in HTTPAuthorization) {
        i++;
        [HTTPAuthorizationString appendFormat:@"%@=%@", key, [HTTPAuthorization objectForKey:key]];
        if (i < [[HTTPAuthorization allKeys] count]) [HTTPAuthorizationString appendString:@"&"];
    }

    [self.headers setObject:HTTPAuthorizationString forKey:@"Authorization"];
}

/* This seems to work better? */
- (void)oAuthifyQueryWithConsumerKey:(NSString *)consumerKey
                      consumerSecret:(NSString *)consumerSecret
                         accessToken:(NSString *)accessToken
                   accessTokenSecret:(NSString *)accessTokenSecret
                     signatureMethod:(TTURLRequestOAuthSignatureMethod)signatureMethod
                             version:(NSString *)version {

    if (!TTIsStringWithAnyText(self.httpMethod)) self.httpMethod = @"GET";
    
    NSDictionary *HTTPAuthorization = [[self class] authDictWithConsumerKey:consumerKey
                                                           consumerSecret:consumerSecret
                                                              accessToken:accessToken
                                                        accessTokenSecret:accessTokenSecret
                                                          signatureMethod:signatureMethod
                                                                  version:version
                                                               parameters:self.parameters
                                                               httpMethod:self.httpMethod
                                                                  urlPath:self.urlPath];

    // Doing this inline so this lib doesn't have any dependencies
    NSMutableString *HTTPAuthorizationString = [NSMutableString string];
    
    int i = 0;
    for (NSString *key in HTTPAuthorization) {
        i++;
        [HTTPAuthorizationString appendFormat:@"%@=%@", key, [HTTPAuthorization objectForKey:key]];
        if (i < [[HTTPAuthorization allKeys] count]) [HTTPAuthorizationString appendString:@"&"];
    }

    self.urlPath = [self.urlPath stringByAppendingString:[NSString stringWithFormat:@"?%@", HTTPAuthorizationString]];
}

/* This seems to work too? */
- (void)oAuthifyParamsWithConsumerKey:(NSString *)consumerKey
                       consumerSecret:(NSString *)consumerSecret
                          accessToken:(NSString *)accessToken
                    accessTokenSecret:(NSString *)accessTokenSecret
                      signatureMethod:(TTURLRequestOAuthSignatureMethod)signatureMethod
                              version:(NSString *)version {

    if (!TTIsStringWithAnyText(self.httpMethod)) self.httpMethod = @"GET";

    NSDictionary *HTTPAuthorization = [[self class] authDictWithConsumerKey:consumerKey
                                                           consumerSecret:consumerSecret
                                                              accessToken:accessToken
                                                        accessTokenSecret:accessTokenSecret
                                                          signatureMethod:signatureMethod
                                                                  version:version
                                                               parameters:self.parameters
                                                               httpMethod:self.httpMethod
                                                                  urlPath:self.urlPath];

    [self.parameters setDictionary:HTTPAuthorization];
}

@end

@implementation TTURLRequest (OAuth_Private)

#pragma mark - Private
+ (NSString *)stringForSignatureMethod:(TTURLRequestOAuthSignatureMethod)_signatureMethod {
    switch (_signatureMethod) {
        case TTURLRequestOAuthSignatureMethodHMAC:
            return @"HMAC-SHA1";
            break;
            
        case TTURLRequestOAuthSignatureMethodRSA:
            return @"RSA-SHA1";
            break;
            
        case TTURLRequestOAuthSignatureMethodPlaintext:
        default:
            return @"PLAINTEXT";
    }
    return @"PLAINTEXT";
}

/* Taken from OAuthConsumer::OAMutableURLRequest */
+ (NSString *)nonce:(int)length {
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    id _theUUID = NSMakeCollectable(theUUID);
    NSString *retVal = [[(NSString*)string stringByReplacingOccurrencesOfString:@"-" withString:@""] lowercaseString];
    CFRelease(string);
    [_theUUID release];
    return retVal;
}


#pragma mark - Signature

/* Original source of this method from http://oauth.googlecode.com/svn/code/obj-c/OAuthConsumer/ */
+ (NSString *)signatureBaseStringWithURL:(NSURL*)URL
                              httpMethod:(NSString *)httpMethod
                       requestParameters:(NSDictionary *)requestParameters {

    // OAuth Spec, Section 9.1.1 "Normalize Request Parameters"
    // build a sorted array of both request parameters and OAuth header parameters
    NSMutableArray *parameterPairs = [NSMutableArray  arrayWithCapacity:(6 + [requestParameters count])]; // 6 being the number of OAuth params in the Signature Base String

    for (NSString *key in [requestParameters allKeys]) {
        [parameterPairs addObject:[NSString stringWithFormat:@"%@=%@", key, [requestParameters objectForKey:key]]];
    }

    NSArray *sortedPairs = [parameterPairs sortedArrayUsingSelector:@selector(compare:)];
    NSString *normalizedRequestParameters = [sortedPairs componentsJoinedByString:@"&"];

    // OAuth Spec, Section 9.1.2 "Concatenate Request Elements"
    NSString *URLStringWithoutQuery = [[[URL absoluteString] componentsSeparatedByString:@"?"] objectAtIndex:0];
    NSString *ret = [NSString stringWithFormat:@"%@&%@&%@",
					 httpMethod,
					 [URLStringWithoutQuery urlEncoded],
					 [normalizedRequestParameters urlEncoded]];

	return ret;
}

+ (NSString *)signatureStringWithURL:(NSURL*)URL
                         httpMethod:(NSString *)httpMethod
                    signatureMethod:(TTURLRequestOAuthSignatureMethod)signatureMethod
                        accessToken:(NSString *)token
                        tokenSecret:(NSString *)tokenSecret
                     consumerSecret:(NSString *)consumerSecret
                  requestParameters:(NSDictionary *)requestParameters {
    
    id <OASignatureProviding> provider = nil;
    if (signatureMethod == TTURLRequestOAuthSignatureMethodHMAC) {
        provider = [[[OAHMAC_SHA1SignatureProvider alloc] init] autorelease];
    } else {
        provider = [[[OAPlaintextSignatureProvider alloc] init] autorelease];
    }
    
    NSString *signature = [provider signClearText:[[self class] signatureBaseStringWithURL:URL
                                                                                httpMethod:httpMethod
                                                                         requestParameters:requestParameters]
                                       withSecret:[NSString stringWithFormat:@"%@&%@",
                                                   [consumerSecret urlEncoded],
                                                   [tokenSecret urlEncoded]]];
    
    return [NSString stringWithString:[signature urlEncoded]];
}


#pragma mark - Authorization String

+ (NSDictionary *)authDictWithConsumerKey:(NSString *)consumerKey
                           consumerSecret:(NSString *)consumerSecret
                              accessToken:(NSString *)accessToken
                        accessTokenSecret:(NSString *)accessTokenSecret
                          signatureMethod:(TTURLRequestOAuthSignatureMethod)signatureMethod
                                  version:(NSString *)version
                               parameters:(NSDictionary *)parameters
                               httpMethod:(NSString *)httpMethod
                                  urlPath:(NSString *)urlPath {

    NSMutableDictionary *HTTPAuthorization = [[parameters mutableCopy] autorelease];
    if (consumerKey) [HTTPAuthorization setObject:consumerKey forKey:@"oauth_consumer_key"];
    if (accessToken) [HTTPAuthorization setObject:accessToken forKey:@"oauth_token"];
    [HTTPAuthorization setObject:[[TTURLRequest class] stringForSignatureMethod:signatureMethod] forKey:@"oauth_signature_method"];
    [HTTPAuthorization setObject:[NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]] forKey:@"oauth_timestamp"];
    [HTTPAuthorization setObject:[[TTURLRequest class] nonce:kDefaultNonceLength] forKey:@"oauth_nonce"];
    if (version) [HTTPAuthorization setObject:version forKey:@"oauth_version"];

    [HTTPAuthorization setObject:[[TTURLRequest class] signatureStringWithURL:[NSURL URLWithString:urlPath]
                                                                   httpMethod:httpMethod
                                                              signatureMethod:signatureMethod
                                                                  accessToken:accessToken
                                                                  tokenSecret:accessTokenSecret
                                                               consumerSecret:consumerSecret
                                                            requestParameters:HTTPAuthorization] forKey:@"oauth_signature"];

    return HTTPAuthorization;
}

@end
