#ifndef __HELLOWORLD_SCENE_H__
#define __HELLOWORLD_SCENE_H__

#include "cocos2d.h"
USING_NS_CC;

class HelloWorld : public cocos2d::Layer
{
public:
    static cocos2d::Scene* createScene();

     virtual bool init() override;
    
    //其它函数省略
    virtual void visit(Renderer *renderer, const Mat4& parentTransform, uint32_t parentFlags) override;
    
    void onDraw();
    CREATE_FUNC(HelloWorld);
private:
    CustomCommand _command;
};

#endif // __HELLOWORLD_SCENE_H__
