//
//  OpenGLView.h
//  OpenGLTest
//
//  Created by jianghai on 2017/2/25.
//  Copyright © 2017年 GetURL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
@interface OpenGLView : UIView {
    
    CAEAGLLayer *_eaglLayer;
    EAGLContext *_context;
    GLuint       _colorRenderBuffer;
    
}

@end
