//
//  FaceProcessor.h
//
//  Created by Dave Peck on 5/9/12.
//  Copyright (c) 2012 Skull Ninja Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol FaceProcessorDelegate <NSObject>
- (void)facesUpdated:(NSArray *)faces videoRect:(CGRect)rect videoOrientation:(AVCaptureVideoOrientation)orientation;
@optional
- (void)previewImageUpdated:(UIImage *)previewImage;
@end

@interface FaceProcessor : NSObject {
    cv::Mat _prevMat;
    std::vector<cv::Point2f> _points[2];
    std::vector<cv::Point2f> _features;
    std::vector<cv::Point2f> _initial;
    std::vector<uchar> _status;
    std::vector<float> _err;
    
    int _framesSinceLastFeatureCheck;
    
    NSMutableArray *_faces;
    
    id<FaceProcessorDelegate> _delegate;
}

@property (nonatomic, assign) id<FaceProcessorDelegate> delegate;

- (void)processFrame:(cv::Mat &)mat videoRect:(CGRect)rect videoOrientation:(AVCaptureVideoOrientation)orientation;

@end
