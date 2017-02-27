#include "HelloWorldScene.h"

USING_NS_CC;

Scene* HelloWorld::createScene()
{
    // 'scene' is an autorelease object
    auto scene = Scene::create();
    
    // 'layer' is an autorelease object
    auto layer = HelloWorld::create();

    // add layer as a child to scene
    scene->addChild(layer);

    // return the scene
    return scene;
}

// on "init" you need to initialize your instance
bool HelloWorld::init() 
{
    //////////////////////////////
    // 1. super init first
    if ( !Layer::init() )
    {
        return false;
    }
    
    
    auto program = new GLProgram();
    
    program->initWithFilenames("vertexShader.vert", "fragmentShader.frag");
    program->link();
    program->updateUniforms();
    this->setGLProgram(program);
    return true;
}


void HelloWorld::visit(Renderer *renderer, const Mat4& parentTransform, uint32_t parentFlags)
{
    Layer::visit(renderer, parentTransform, parentFlags);
    _command.init(_globalZOrder);
    _command.func = CC_CALLBACK_0(HelloWorld::onDraw, this);
    Director::getInstance()->getRenderer()->addCommand(&_command);
}

void HelloWorld::onDraw()
{
    //获得当前HelloWorld的shader
    auto glProgram = getGLProgram();
    //使用此shader
    glProgram->use();
    //设置该shader的一些内置uniform,主要是MVP，即model-view-project矩阵
    glProgram->setUniformsForBuiltins();
    
    
    GLuint vao;
    glGenVertexArrays(1,&vao);
    glBindVertexArray(vao);
    
    
    
    
    
    
    auto size = Size(100, 100);//Director::getInstance()->getWinSize();
    //指定将要绘制的顶点 只能用三角形的形式定义
    float vertecies[] = {
        0,50,
        size.width,50,
        size.width,50 + size.height,
        100,50 + size.height,
        100 + size.width, 50 + size.height,
        100,50,
        200,50,
        400,50,
        300,200,
    };
    //指定每一个顶点的颜色，颜色值是RGBA格式的，取值范围是0-1
    float colors[] = {
        1,0,0,1,
        0,1,0,1,
        0,0,1,1,
        1,1,1,1,
        0,0,1,1,
        1,0,0,1,
        1,0,1,1,
        0,1,1,1,
        1,1,0,1,
    };
    
     //set for vertex
    
    //创建和绑定vbo
    GLuint vertexVBO;
    glGenBuffers(1, &vertexVBO);
    glBindBuffer(GL_ARRAY_BUFFER, vertexVBO);
    //glBufferData把我们定义好的顶点和颜色数据传给VBO
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertecies), vertecies, GL_STATIC_DRAW);
    
    //获取vertex attribute "a_position"的入口点
    GLuint positionLocation = glGetAttribLocation(glProgram->getProgram(), "a_position");
    
    //打开入a_position入口点
    //在我们要传递数据之前，首先要告诉OpenGL，所以要调用glEnableVertexAttribArray
    glEnableVertexAttribArray(positionLocation);
    
    //传递顶点数据给a_position，注意最后一个参数是数组的偏移了。
    //通过glVertexAttribPointer传如数据
    glVertexAttribPointer(positionLocation, 2, GL_FLOAT, GL_FALSE, 0, (GLvoid *)0);
    
    
    
    //set for color
    GLuint colorVBO;
    glGenBuffers(1, &colorVBO);
    glBindBuffer(GL_ARRAY_BUFFER, colorVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(colors), colors, GL_STATIC_DRAW);
    GLuint colorLocation = glGetAttribLocation(glProgram->getProgram(), "a_color");
    glEnableVertexAttribArray(colorLocation);
    glVertexAttribPointer(colorLocation, 4, GL_FLOAT, GL_FALSE, 0, (GLvoid*)0);
    //for safty
//    glBindVertexArray(0);
//    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    
    
    
//    //激活名字为position和color的vertex attribute
//    GL::enableVertexAttribs(GL::VERTEX_ATTRIB_FLAG_POSITION | GL::VERTEX_ATTRIB_FLAG_COLOR);
//    //分别给position和color指定数据源
//    glVertexAttribPointer(GLProgram::VERTEX_ATTRIB_POSITION, 2, GL_FLOAT, GL_FALSE, 0, vertecies);
//    glVertexAttribPointer(GLProgram::VERTEX_ATTRIB_COLOR, 4, GL_FLOAT, GL_FALSE, 0, colors);
    //绘制三角形，所谓的draw call就是指这个函数调用
    glDrawArrays(GL_TRIANGLES, 0, 9);
    //通知cocos2d-x 的renderer，让它在合适的时候调用这些OpenGL命令
    CC_INCREMENT_GL_DRAWN_BATCHES_AND_VERTICES(1, 3);
    //如果出错了，可以使用这个函数来获取出错信息
    CHECK_GL_ERROR_DEBUG();
    
}

