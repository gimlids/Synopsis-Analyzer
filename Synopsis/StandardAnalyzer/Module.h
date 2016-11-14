//
//  Module.h
//  Synopsis
//
//  Created by vade on 11/10/16.
//  Copyright © 2016 metavisual. All rights reserved.
//

#import "opencv.hpp"
#import "ocl.hpp"
#import "types_c.h"
#import "utility.hpp"

#import "StandardAnalyzerDefines.h"
#import <Foundation/Foundation.h>
#import "AnalyzerPluginProtocol.h"

@interface Module : NSObject

- (instancetype) initWithQualityHint:(SynopsisAnalysisQualityHint)qualityHint NS_DESIGNATED_INITIALIZER;

@property (readonly) SynopsisAnalysisQualityHint qualityHint;

- (NSString*) moduleName;
- (FrameCacheFormat) currentFrameFormat;
- (FrameCacheFormat) previousFrameFormat;

- (NSDictionary*) analyzedMetadataForCurrentFrame:(matType)frame previousFrame:(matType)lastFrame;
- (NSDictionary*) finaledAnalysisMetadata;


@end
