//
//  OpenGLView.m
//  OpenGLTest
//
//  Created by jianghai on 2017/2/25.
//  Copyright © 2017年 GetURL. All rights reserved.
//

#import "OpenGLView.h"
#import "CC3GLMatrix.h"

@interface DrawView : UIView

@end
@implementation DrawView
//替换UIView的默认layer
+ (Class)layerClass {
    return [CAEAGLLayer class];
}

@end


@interface OpenGLView ()
@property (nonatomic , assign) GLuint positionSlot;
@property (nonatomic , assign) GLuint colorSlot;
@property (nonatomic , assign) GLuint projectionUniform;
@property (nonatomic , strong) DrawView *renderView;
@end



typedef struct {
    float Position[3];//xyz
    float Color[4];//rgba
} Vertex;

//const Vertex Vertices[] = {//顶点信息(位置,颜色)
//    {{1, -1, 0}, {1, 1, 0, 1}},
//    {{1, 1, 0}, {0, 1, 0, 1}},
//    {{-1, 1, 0}, {0, 0.5, 1, 1}},
//    {{-1, -1, 0}, {0, 0.2, 0, 1}}
//};

const GLubyte Indices[] = {//一个用于表示三角形顶点的数组.
    0, 1, 2,
    2, 3, 0
};

const Vertex Vertices[] = {
    {{1, -1, -7}, {1, 0, 0, 1}},
    {{1, 1, -7}, {0, 1, 0, 1}},
    {{-1, 1, -2}, {0, 0, 1, 1}},
    {{-1, -1, -2}, {0, 0, 0, 1}}
};

@implementation OpenGLView

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        _renderView = [[DrawView alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
        [self addSubview:_renderView];
        [self setupLayer];
        [self setupContext];
        [self setupRenderBuffer];
        [self setupFrameBuffer];
        [self compileShader];
        [self setupVBOs];
        [self render];
        
        return self;
    }
    return nil;
}

-(void)dealloc {
    _context = nil;
}

//替换UIView的默认layer
+ (Class)layerClass {
    return [CAEAGLLayer class];
}

//初始化OpenGLlayer
- (void)setupLayer {
    _eaglLayer = (CAEAGLLayer *) self.renderView.layer;
    _eaglLayer.opaque = YES;//因为缺省的话,CALayer是透明的.而透明的层对性能负荷很大,特别是OpenGL的层.
}

//初始化OpenGL Context
- (void)setupContext {
    EAGLRenderingAPI renderApi = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:renderApi];
    
    if (!_context) {
        NSLog(@"create context failed!");
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"set context failed !");
        exit(1);
    }
}

//初始化渲染缓冲区
//Render buffer 是OpenGL的一个对象,用于存放渲染过的图像.
- (void)setupRenderBuffer {
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

//初始化帧缓冲区
//Frame buffer也是OpenGL的对象,它包含了前面提到的render buffer,以及其它:depth buffer、stencil buffer 和 accumulation buffer.
- (void)setupFrameBuffer {
    GLuint frameBuffer;
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
}

- (void)render {
    glClearColor(1, 1, 1, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);//用到GL_COLOR_BUFFER_BIT来声明要清理哪一个缓冲区.
                                 //GL_DEPTH_BUFFER_BIT
                                 //GL_STENCIL_BUFFER_BIT 这三个可选
                                 //GL_COLOR_BUFFER_BIT
    
    
    
    CC3GLMatrix *projection = [CC3GLMatrix matrix];
    float h = 4.0f * self.frame.size.height / self.frame.size.width;
    [projection populateFromFrustumLeft:-2 andRight:2 andBottom:-h/2 andTop:h/2 andNear:4 andFar:100];
    glUniformMatrix4fv(_projectionUniform, 1, 0, projection.glMatrix);
    
    
    //设置UIView中用于渲染的部分,从EAGLLayer左下角偏移
    glViewport(0, 0, self.renderView.frame.size.width, self.renderView.frame.size.height);
    
    /*调用glVertexAttribPointer来为vertex shader的两个输入参数配置两个合适的值.
     第二段这里,是一个很重要的方法,让我们来认真地看看它是如何工作的：
     第一个参数,声明这个属性的名称,之前我们称之为glGetAttribLocation
     第二个参数,定义这个属性由多少个值组成.譬如说position是由3个float(x,y,z)组成,而颜色是4个float(r,g,b,a)
     第三个,声明每一个值是什么类型.(这例子中无论是位置还是颜色,我们都用了GL_FLOAT)
     第四个,嗯……它总是false就好了.
     第五个,指 stride 的大小.这是一个种描述每个vertex数据大小的方式.所以我们可以简单地传入 sizeof(Vertex),让编译器计算出来就好.
     最后一个,是这个数据结构的偏移量.表示在这个结构中,从哪里开始获取我们的值.Position的值在前面,所以传0进去就可以了.
     而颜色是紧接着位置的数据,而position的大小是3个float的大小,所以是从 3 * sizeof(float) 开始的.*/
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) *3));
    
    
    
    
    /*
     调用glDrawElements ,它最后会在每个vertex上调用我们的vertex shader,以及每个像素调用fragment shader,最终画出我们的矩形。
     它也是一个重要的方法,我们来仔细研究一下：
        第一个参数,声明用哪种特性来渲染图形。有GL_LINE_STRIP 和 GL_TRIANGLE_FAN。然而GL_TRIANGLE是最常用的,特别是与VBO 关联的时候。
        第二个,告诉渲染器有多少个图形要渲染。我们用到C的代码来计算出有多少个。这里是通过个 array的byte大小除以一个Indice类型的大小得到的。
        第三个,指每个indices中的index类型
        最后一个,在官方文档中说,它是一个指向index的指针。但在这里,我们用的是VBO,所以通过index的array就可以访问到了,在GL_ELEMENT_ARRAY_BUFFER传过了,所以这里不需要.
     */
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)setupVBOs {
    
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);//创建一个Vertex Buffer 对象
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);//绑定GL_ARRAY_BUFFER和vertexBuffer
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);// 把数据传到OpenGL-land
    
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
}

- (void)compileShader {
    
    //调用动态编译方法,分别编译了vertex shader 和 fragment shader
    GLuint vertexShader = [self compileShader:@"SimpleVertex" withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"SimpleFragment" withType:GL_FRAGMENT_SHADER];
    
    //连接 vertex 和 fragment shader成一个完整的program.
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    
    //检查是否有error,并输出信息.
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"link error :%@", messageString);
        exit(1);
    }
    
    //让OpenGL真正执行你的program
    glUseProgram(programHandle);
    
    //调用 glGetAttribLocation 来获取指向 vertex shader传入变量的指针
    //以后就可以通过这写指针来使用了
    //还有调用 glEnableVertexAttribArray来启用这些数据默认是 disabled的
    _positionSlot = glGetAttribLocation(programHandle, "Position");
    _colorSlot = glGetAttribLocation(programHandle, "SourceColor");
    _projectionUniform = glGetUniformLocation(programHandle, "Projection");//这些是在vertex中定义的变量
    
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);
    glEnableVertexAttribArray(_projectionUniform);
}

- (GLuint)compileShader:(NSString *)shaderName withType:(GLenum)shaderType {
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
    NSError *error = nil;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    
    if (!shaderString) {
        NSLog(@"error loading shader %@",error.localizedDescription);
        exit(1);
    }
    
    //调用 glCreateShader来创建一个代表shader 的OpenGL对象
    //这时你必须告诉OpenGL,你想创建 fragment shader还是vertex shader
    //所以便有了这个参数:shaderType
    GLuint shaderHandle = glCreateShader(shaderType);
    
    
    const char *shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = [shaderString length];
    //调用glShaderSource,让OpenGL获取到这个shader的源代码
    //这里我们还需要把NSString转换成C-string
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    //调用glCompileShader 在运行时编译shader
    glCompileShader(shaderHandle);
    
    //如果编译失败了,我们必须一些信息来找出问题原因
    //glGetShaderiv 和 glGetShaderInfoLog会把error信息输出到屏幕然后退出
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"compile error :%@", messageString);
        exit(1);
    }
    
    return shaderHandle;
}
@end
