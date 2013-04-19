//
//  DetectedFaceFeatures.h
//
//  Created by Dave Peck on 5/9/12.
//  Copyright (c) 2012 Skull Ninja Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DetectedFaceFeatures : NSObject {
    CGPoint _mouth;
    CGPoint _mouthUpperLip;
    CGPoint _mouthBottomLip;
    CGPoint _mouthLeft;
    CGPoint _mouthRight;
    CGPoint _leftEye;
    CGPoint _rightEye;
}

@property (readwrite, nonatomic, assign) CGPoint mouth;
@property (readwrite, nonatomic, assign) CGPoint mouthUpperLip;
@property (readwrite, nonatomic, assign) CGPoint mouthBottomLip;
@property (readwrite, nonatomic, assign) CGPoint mouthLeft;
@property (readwrite, nonatomic, assign) CGPoint mouthRight;
@property (readwrite, nonatomic, assign) CGPoint leftEye;
@property (readwrite, nonatomic, assign) CGPoint rightEye;

@end
