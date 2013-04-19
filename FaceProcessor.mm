//
//  FaceProcessor.m
//
//  Created by Dave Peck on 5/9/12.
//  Copyright (c) 2012 Skull Ninja Inc. All rights reserved.
//

#import "FaceProcessor.h"
#import "DetectedFaceFeatures.h"

int const kNumberOfFaceFeaturesTracked = 7;

@implementation FaceProcessor

@synthesize delegate = _delegate;

- (id)init {
    self = [super init];
    if (self) {
        _faces = [[NSMutableArray alloc] initWithCapacity:4];
        _framesSinceLastFeatureCheck = 0;
    }
    return self;
}


- (BOOL)addNewPoints {
    return _framesSinceLastFeatureCheck > 60 || _points[0].size() < MAX(1, (kNumberOfFaceFeaturesTracked * [_faces count]));
}

- (void)detectFeaturedPoints:(cv::Mat &)mat {
    
    _framesSinceLastFeatureCheck = 0;
    
    UIImage *tempImage = [UIImage imageWithCVMat:mat];
    CIImage *orientedImage = [CIImage imageWithCGImage:tempImage.CGImage];
    
    NSDictionary *options = [NSDictionary dictionaryWithObject:CIDetectorAccuracyLow forKey:CIDetectorAccuracy];
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:options];
    
    NSArray *faces = [detector featuresInImage:orientedImage];
    
    if ([faces count] == 0) {
        NSLog(@"Number of Points: %lu", _points[0].size());
        if (_points[0].size() == (kNumberOfFaceFeaturesTracked * [_faces count])) {
            return; // If no faces are found, then do not clear any existing points (assuming they are valid).
        }
    }
    
    //Reject all existing points
    _points[0].clear();
    _points[1].clear();
    _initial.clear();
    
    _features.clear();
    [_faces removeAllObjects];
    
    float upperLipFactor = 0.92;
    float bottomLipFactor = 1.08;
    
    for (CIFaceFeature *face in faces) {
        
        if (!face.hasMouthPosition || !face.hasLeftEyePosition
            || !face.hasRightEyePosition) continue;
        
        // Mouth Center
        _features.insert(_features.end(), cv::Point2f(face.mouthPosition.x, tempImage.size.height - face.mouthPosition.y));
        
        // Upper Lip
        _features.insert(_features.end(), cv::Point2f(face.mouthPosition.x, (tempImage.size.height - face.mouthPosition.y) * upperLipFactor));
        
        // Bottom Lip
        _features.insert(_features.end(), cv::Point2f(face.mouthPosition.x, (tempImage.size.height - face.mouthPosition.y) * bottomLipFactor));
        
        // Mouth Left / Right
        _features.insert(_features.end(), cv::Point2f(face.leftEyePosition.x, tempImage.size.height - face.mouthPosition.y));
        _features.insert(_features.end(), cv::Point2f(face.rightEyePosition.x, tempImage.size.height - face.mouthPosition.y));
        
        // Left / Right Eyes
        _features.insert(_features.end(), cv::Point2f(face.leftEyePosition.x, tempImage.size.height - face.leftEyePosition.y));
        _features.insert(_features.end(), cv::Point2f(face.rightEyePosition.x, tempImage.size.height - face.rightEyePosition.y));
        
        DetectedFaceFeatures *df = [[[DetectedFaceFeatures alloc] init] autorelease];
        df.mouth = CGPointMake(face.mouthPosition.x, tempImage.size.height - face.mouthPosition.y);
        df.mouthUpperLip = CGPointMake(face.mouthPosition.x, (tempImage.size.height - face.mouthPosition.y) * upperLipFactor);
        df.mouthBottomLip = CGPointMake(face.mouthPosition.x, (tempImage.size.height - face.mouthPosition.y) * bottomLipFactor);
        df.mouthLeft = CGPointMake(face.leftEyePosition.x, tempImage.size.height - face.mouthPosition.y);
        df.mouthRight = CGPointMake(face.rightEyePosition.x, tempImage.size.height - face.mouthPosition.y);
        df.leftEye = CGPointMake(face.leftEyePosition.x, tempImage.size.height - face.leftEyePosition.y);
        df.rightEye = CGPointMake(face.rightEyePosition.x, tempImage.size.height - face.rightEyePosition.y);
        
        [_faces addObject:df];
    }
    
    // add the detected features to
    // the currently tracked features
    _points[0].insert(_points[0].end(),
                      _features.begin(),_features.end());
    _initial.insert(_initial.end(),
                    _features.begin(),_features.end());
    
}

- (BOOL)acceptTrackedPoint:(int)i {
    return _status[i];// &&
    // if point has moved
    //(abs(_points[0][i].x-_points[1][i].x)+
    //(abs(_points[0][i].y-_points[1][i].y))>2);
}

// handle the currently tracked points
- (void)handleTrackedPoints:(cv:: Mat &)frame output:(cv:: Mat &)output {
    cv::Mat clone = frame.clone();
    
    // for all tracked points
    for(int i= 0; i < _points[1].size(); i++ ) {
        // draw line and circle
        cv::line(clone,
                 _initial[i],  // initial position
                 _points[1][i],// new position
                 cv::Scalar(255,255,255));
        cv::circle(clone, _points[1][i], 3,
                   cv::Scalar(255,255,255),-1);
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(previewImageUpdated:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate previewImageUpdated:[UIImage imageWithCVMat:clone]];
        });
    }
    
}

- (void)processFrame:(cv::Mat &)mat videoRect:(CGRect)rect videoOrientation:(AVCaptureVideoOrientation)videOrientation {
    //Mostly from: http://stackoverflow.com/questions/11492247/parameters-for-opencv-eye-detector-in-iphone

    // Shrink video frame to 320X240
    cv::resize(mat, mat, cv::Size(), 0.25f, 0.25f, CV_INTER_LINEAR);
    rect.size.width /= 4.0f;
    rect.size.height /= 4.0f;
    
    //Sharpen
    //cv::Mat clone = mat.clone();
    //cv::GaussianBlur(clone, mat, cv::Size(), 3);
    //cv::addWeighted(clone, 1.5, mat, -0.5, 0, mat);
    
    cv::transpose(mat, mat);
    CGFloat temp = rect.size.width;
    rect.size.width = rect.size.height;
    rect.size.height = temp;
    
    if (videOrientation == AVCaptureVideoOrientationLandscapeRight)
    {
        // flip around y axis for back camera
        cv::flip(mat, mat, 1);
    }
    else {
        // Front camera output needs to be mirrored to match preview layer so no flip is required here
    }
    
    videOrientation = AVCaptureVideoOrientationPortrait;
    
    if ([self addNewPoints]) {
        
        // Check for faces
        [self detectFeaturedPoints:mat];
        
    } else {
        _framesSinceLastFeatureCheck++;
    }
    
    if (_prevMat.empty()) {
        mat.copyTo(_prevMat);
    }
    
    if (_points[0].size() > 0) {
        
        cv::calcOpticalFlowPyrLK(
                                 _prevMat, mat, // 2 consecutive images
                                 _points[0], // input point positions in first image
                                 _points[1], // output point positions in the 2nd image
                                 _status,    // tracking success
                                 _err);
        
        
        // 2. loop over the tracked points to reject some
        int k=0;
        int accepted = 0;
        int rejected = 0;
        for( int i= 0; i < _points[1].size(); i++ ) {
            // do we keep this point?
            if ([self acceptTrackedPoint:i]) {
                accepted++;
                // keep this point in vector
                _initial[k]= _initial[i];
                _points[1][k++] = _points[1][i];
                
                DetectedFaceFeatures *df = [_faces objectAtIndex:(int)(i / kNumberOfFaceFeaturesTracked)];
                
                int currentFeature = i % kNumberOfFaceFeaturesTracked;
                
                switch (currentFeature) {
                    case 0:
                        df.mouth = CGPointMake(_points[1][i].x, _points[1][i].y);
                        break;
                    case 1:
                        df.mouthUpperLip = CGPointMake(_points[1][i].x, _points[1][i].y);
                        break;
                    case 2:
                        df.mouthBottomLip = CGPointMake(_points[1][i].x, _points[1][i].y);
                        break;
                    case 3:
                        df.mouthLeft = CGPointMake(_points[1][i].x, _points[1][i].y);
                        break;
                    case 4:
                        df.mouthRight = CGPointMake(_points[1][i].x, _points[1][i].y);
                        break;
                    case 5:
                        df.leftEye = CGPointMake(_points[1][i].x, _points[1][i].y);
                        break;
                    case 6:
                        df.rightEye = CGPointMake(_points[1][i].x, _points[1][i].y);
                        break;
                }
                
            } else {
                rejected++;
            }
        }
        
        //NSLog(@"Accepted: %i; Rejected: %i", accepted, rejected);
        
        // eliminate unsuccesful points
        _points[1].resize(k);
        _initial.resize(k);
    }
    
    // 4. current points and image become previous ones
    std::swap(_points[1], _points[0]);
    cv::swap(_prevMat, mat);
    
    // 3. handle the accepted tracked points
    [self handleTrackedPoints:mat output:mat];
    
    if (self.delegate) {
        // Dispatch updating of face markers to main queue
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.delegate facesUpdated:_faces videoRect:rect videoOrientation:videOrientation];
        });
    }
}


@end
