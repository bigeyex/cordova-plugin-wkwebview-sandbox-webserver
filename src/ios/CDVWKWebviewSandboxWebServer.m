/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "CDVWKWebviewSandboxWebServer.h"
#import "GCDWebServerPrivate.h"
#import <Cordova/CDVViewController.h>
#import <Cordova/NSDictionary+CordovaPreferences.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <objc/message.h>
#import <netinet/in.h>


#define LOCAL_FILESYSTEM_PATH   @"local-filesystem"
#define ASSETS_LIBRARY_PATH     @"assets-library"
#define ERROR_PATH              @"error"

@interface GCDWebServer()
- (GCDWebServerResponse*)_responseWithContentsOfDirectory:(NSString*)path;
@end


@implementation CDVWKWebviewSandboxWebServer

- (void) pluginInitialize {

    BOOL useLocalWebServer = NO;
    BOOL requirementsOK = NO;
    NSString* indexPage = @"index.html";
    NSString* appBasePath = @"www";
    NSUInteger port = 80;

    // check the content tag src
    CDVViewController* vc = (CDVViewController*)self.viewController;
    NSURL* startPageUrl = [NSURL URLWithString:vc.startPage];
    if (startPageUrl != nil) {
        if ([[startPageUrl scheme] isEqualToString:@"http"] && [[startPageUrl host] isEqualToString:@"localhost"]) {
            port = [[startPageUrl port] unsignedIntegerValue];
            useLocalWebServer = YES;
        }
    }

    requirementsOK = [self checkRequirements];
    if (!requirementsOK) {
        useLocalWebServer = NO;
        NSString* alternateContentSrc = [self.commandDelegate.settings cordovaSettingForKey:@"AlternateContentSrc"];
        vc.startPage = alternateContentSrc? alternateContentSrc : indexPage;
    }

    // check setting
#if TARGET_IPHONE_SIMULATOR
    if (useLocalWebServer) {
        NSNumber* startOnSimulatorSetting = [[self.commandDelegate settings] objectForKey:[@"CordovaLocalWebServerStartOnSimulator" lowercaseString]];
        if (startOnSimulatorSetting) {
            useLocalWebServer = [startOnSimulatorSetting boolValue];
        }
    }
#endif
    
    if (port == 0) {
        // CB-9096 - actually test for an available port, and set it explicitly
        port = [self _availablePort];
    }

    NSString* authToken = [NSString stringWithFormat:@"cdvToken=%@", [[NSProcessInfo processInfo] globallyUniqueString]];

    self.server = [[GCDWebServer alloc] init];
    [GCDWebServer setLogLevel:kGCDWebServerLoggingLevel_Error];

    if (useLocalWebServer) {
        [self addAppFileSystemHandler:authToken basePath:[NSString stringWithFormat:@"/%@/", appBasePath] indexPage:indexPage];

        // add after server is started to get the true port
        [self addFileSystemHandlers:authToken];
        [self addErrorSystemHandler:authToken];
        
        // handlers must be added before server starts
        [self.server startWithPort:port bonjourName:nil];

        // Update the startPage (supported in cordova-ios 3.7.0, see https://issues.apache.org/jira/browse/CB-7857)
		vc.startPage = [NSString stringWithFormat:@"http://localhost:%lu/%@/%@?%@", (unsigned long)self.server.port, appBasePath, indexPage, authToken];

    } else {
        if (requirementsOK) {
            NSString* error = [NSString stringWithFormat:@"WARNING: CordovaLocalWebServer: <content> tag src is not http://localhost[:port] (is %@).", vc.startPage];
            NSLog(@"%@", error);

            [self addErrorSystemHandler:authToken];
            
            // handlers must be added before server starts
            [self.server startWithPort:port bonjourName:nil];

            vc.startPage = [self createErrorUrl:error authToken:authToken];
        } else {
            GWS_LOG_ERROR(@"%@ stopped, failed requirements check.", [self.server class]);
        }
    }
}


@end
