/*
 
 // 2012 Colin Young (edited by Randy Tarampi)

 Purpose
 =======
 
 - Simplifies adding OAuth request parameters to the URL of a TTURLRequest.
 
 Usage
 =====
 
 1. Set up a TTURLRequest normally
 
    TTURLRequest* request = [TTURLRequest
        requestWithURL: url
        delegate: self];
 
 2. Add the OAuth query parameters
 
    [request oauthifyWithConsumerKey:token:signatureMethod:version:]
 
*/

#import <Three20/Three20.h>

typedef enum {
    TTURLRequestOAuthSignatureMethodPlaintext,
    TTURLRequestOAuthSignatureMethodHMAC,
    TTURLRequestOAuthSignatureMethodRSA
} TTURLRequestOAuthSignatureMethod;

@interface TTURLRequest (OAuth)

/* This method is deprecated. Use one of the other two instead. */
- (void)oauthifyWithConsumerKey:(NSString *)consumerKey
                 consumerSecret:(NSString *)consumerSecret
                    accessToken:(NSString *)accessToken
              accessTokenSecret:(NSString *)accessTokenSecret
                signatureMethod:(TTURLRequestOAuthSignatureMethod)signatureMethod
                        version:(NSString *)version __attribute__((deprecated));

- (void)oAuthifyHeaderWithConsumerKey:(NSString *)consumerKey
                       consumerSecret:(NSString *)consumerSecret
                          accessToken:(NSString *)accessToken
                    accessTokenSecret:(NSString *)accessTokenSecret
                      signatureMethod:(TTURLRequestOAuthSignatureMethod)signatureMethod
                              version:(NSString *)version;

- (void)oAuthifyQueryWithConsumerKey:(NSString *)consumerKey
                       consumerSecret:(NSString *)consumerSecret
                          accessToken:(NSString *)accessToken
                    accessTokenSecret:(NSString *)accessTokenSecret
                      signatureMethod:(TTURLRequestOAuthSignatureMethod)signatureMethod
                              version:(NSString *)version;

- (void)oAuthifyParamsWithConsumerKey:(NSString *)consumerKey
                       consumerSecret:(NSString *)consumerSecret
                          accessToken:(NSString *)accessToken
                    accessTokenSecret:(NSString *)accessTokenSecret
                      signatureMethod:(TTURLRequestOAuthSignatureMethod)signatureMethod
                              version:(NSString *)version;

@end
