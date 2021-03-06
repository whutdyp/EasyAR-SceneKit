/**
* Copyright (c) 2015-2016 VisionStar Information Technology (Shanghai) Co., Ltd. All Rights Reserved.
* EasyAR is the registered trademark or trademark of VisionStar Information Technology (Shanghai) Co., Ltd in China
* and other countries for the augmented reality technology developed by VisionStar Information Technology (Shanghai) Co., Ltd.
*/

#import "ViewController.h"

@interface ViewController ()<SCNSceneRendererDelegate>
@property (weak, nonatomic) IBOutlet SCNView *scnView;
@property(strong,nonatomic)SCNNode *sunNode,*earthNode,*moonNode,*earthGroupNode,*sunHaloNode,*cameraNode,*earthRotationNode;
@property(nonatomic)int type;
@property (assign, nonatomic) SCNMatrix4 projection4Matrix;
@property (assign, nonatomic) SCNMatrix4 cameraview4Matrix;
@property (strong, nonatomic) CADisplayLink *displayLink;

@end

@implementation ViewController
#pragma mark 生命周期
- (void)viewDidLoad {
    [super viewDidLoad];
    self.glView = [[OpenGLView alloc] initWithFrame:self.view.bounds];
    [self.view insertSubview:self.glView belowSubview:self.scnView];
    [self.glView setOrientation:self.interfaceOrientation];
    
    
    [self initScene];
    self.sunNode.hidden = YES;
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.glView start];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.glView stop];
}

-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    [self.glView resize:self.view.bounds orientation:self.interfaceOrientation];
}


#pragma mark 组件初始化方法

-(void)initScene{
    //初始化场景,摄像机,手势
    [self setupScene];
    //初始化星球节点
    [self initPlanetNode];
    //添加辅助节点和动作,使星球转公转
    [self roationNode];
    //添加其他节点和效果
    [self addOtherNode];
}
- (void)setupScene {
    // 创建一个新的scene
    SCNScene *scene = [[SCNScene alloc] init];
    // 创建并添加一个camera到scene
    SCNNode *cameraNode = [SCNNode node];
    self.cameraNode = cameraNode;
    cameraNode.camera = [SCNCamera camera];
    [scene.rootNode addChildNode:cameraNode];
    
    // 放置camera
    cameraNode.position = SCNVector3Make(0,0,0);
    cameraNode.camera.zFar = 300;
    cameraNode.rotation =  SCNVector4Make(0, 0, 1, -M_PI_2);
    
    // 设置scene到scnView
    _scnView.scene = scene;
    _scnView.delegate = self;
    // 显示统计信息如fps和时间
    _scnView.showsStatistics = YES;
    // scnView背景色透明
    _scnView.backgroundColor = [UIColor clearColor];
    _scnView.autoenablesDefaultLighting = YES;
    // 添加手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    NSMutableArray *gestureRecognizers = [NSMutableArray array];
    [gestureRecognizers addObject:tapGesture];
    [gestureRecognizers addObjectsFromArray:_scnView.gestureRecognizers];
    _scnView.gestureRecognizers = gestureRecognizers;
}
-(void)initPlanetNode{
    //建立子节点
    _sunNode = [SCNNode new];
    _earthNode = [SCNNode new];
    _moonNode = [SCNNode new];
    _earthGroupNode = [SCNNode new];
    //子节点的几何体,球体
    _sunNode.geometry = [SCNSphere sphereWithRadius:2.5];
    _earthNode.geometry = [SCNSphere sphereWithRadius:1.0];
    _moonNode.geometry = [SCNSphere sphereWithRadius:0.5];
    //月球节点位置
    _moonNode.position = SCNVector3Make(3, 0, 0);
    
    
    //地球节点添加到群,设置位置
    [_earthGroupNode addChildNode:_earthNode];
    _earthGroupNode.position = SCNVector3Make(10, 0, 0);
    _earthGroupNode.rotation =  SCNVector4Make(0, 0, 1, -M_PI);
    
    //太阳节点位置
    _sunNode.position = SCNVector3Make(0, 0, 0);
    //太阳节点添加到根节点
    [_scnView.scene.rootNode addChildNode:_sunNode];
    

    // 添加各星球材质
    _earthNode.geometry.firstMaterial.diffuse.contents = @"art.scnassets/earth/earth-diffuse-mini.jpg";
    _earthNode.geometry.firstMaterial.emission.contents = @"art.scnassets/earth/earth-emissive-mini.jpg";
    _earthNode.geometry.firstMaterial.specular.contents = @"art.scnassets/earth/earth-specular-mini.jpg";
    _moonNode.geometry.firstMaterial.diffuse.contents = @"art.scnassets/earth/moon.jpg";
    _sunNode.geometry.firstMaterial.multiply.contents = @"art.scnassets/earth/sun.jpg";
    _sunNode.geometry.firstMaterial.diffuse.contents = @"art.scnassets/earth/sun.jpg";
    _sunNode.geometry.firstMaterial.multiply.intensity = 0.5;
    _sunNode.geometry.firstMaterial.lightingModelName = SCNLightingModelConstant;
    
    _sunNode.geometry.firstMaterial.multiply.wrapS =
    _sunNode.geometry.firstMaterial.diffuse.wrapS  =
    _sunNode.geometry.firstMaterial.multiply.wrapT =
    _sunNode.geometry.firstMaterial.diffuse.wrapT  = SCNWrapModeRepeat;
    
    _earthNode.geometry.firstMaterial.locksAmbientWithDiffuse =
    _moonNode.geometry.firstMaterial.locksAmbientWithDiffuse  =
    _sunNode.geometry.firstMaterial.locksAmbientWithDiffuse   = YES;
    
    _earthNode.geometry.firstMaterial.shininess = 0.1;
    _earthNode.geometry.firstMaterial.specular.intensity = 0.5;
    _moonNode.geometry.firstMaterial.specular.contents = [UIColor grayColor];
}
//动画效果
-(void)roationNode{
    // Rotate the moon月球自转
    [_moonNode runAction:[SCNAction repeatActionForever:[SCNAction rotateByX:0 y:2 z:0 duration:2]]];
    // 月球旋转节点,用来让月球绕地球转
    SCNNode *moonRotationNode = [SCNNode node];
    [moonRotationNode addChildNode:_moonNode];
    //[moonRotationNode runAction:[SCNAction repeatActionForever:[SCNAction rotateByX:0 y:2 z:0 duration:2]]];
    //添加到地球节点组
    [_earthGroupNode addChildNode:moonRotationNode];
    
    //默认使用正常旋转模式
    if(_type==0){    //  normal Roation
        // 地球旋转节点
        SCNNode *earthRotationNode = [SCNNode node];
        self.earthRotationNode = earthRotationNode;
        //添加到太阳上
        [_sunNode addChildNode:earthRotationNode];
        [_earthNode runAction:[SCNAction repeatActionForever:[SCNAction rotateByX:0 y:2 z:0 duration:2]]];   //地球自转
        // 将地球群组添加到地球旋转节点上,让地球绕太阳旋转
        [earthRotationNode addChildNode:_earthGroupNode];
        [earthRotationNode runAction:[SCNAction repeatActionForever:[SCNAction rotateByX:0 y:2 z:0 duration:10.0]]];
        
    }
    //或者可改为数学计算旋转
    else{   // math roation
        [_sunNode addChildNode:_earthGroupNode];
        [self mathRoation];
    }
}
- (void)addOtherNode {
    //给地球添加云彩
    [self addCloudToEarth];
    //给太阳添加地球轨道
    [self addEarthOrbitToSun];
    //给太阳添加灯泡效果
    [self addLightToSun];
    //给太阳添加光晕效果
    //[self addHaloToSun];
    //太阳的熔岩效果
    [self addAnimationToSun];
}

- (void)addCloudToEarth {
    //地球的云彩节点
    SCNNode *cloudsNode = [SCNNode node];
    cloudsNode.geometry = [SCNSphere sphereWithRadius:1.15];
    cloudsNode.opacity = 0.5;
    // This effect can also be achieved with an image with some transparency set as the contents of the 'diffuse' property
    cloudsNode.geometry.firstMaterial.transparent.contents = @"art.scnassets/earth/cloudsTransparency.png";
    cloudsNode.geometry.firstMaterial.transparencyMode = SCNTransparencyModeRGBZero;
    cloudsNode.geometry.firstMaterial.doubleSided = YES;
    //添加到地球节点上
    [_earthNode addChildNode:cloudsNode];
}
- (void)addEarthOrbitToSun {
    //地球轨道节点
    SCNNode *earthOrbit = [SCNNode node];
    earthOrbit.opacity = 0.4;
    earthOrbit.geometry = [SCNPlane planeWithWidth:21 height:21];
    earthOrbit.geometry.firstMaterial.diffuse.contents = @"art.scnassets/earth/orbit.png";
    earthOrbit.geometry.firstMaterial.diffuse.mipFilter = SCNFilterModeLinear;
    earthOrbit.rotation = SCNVector4Make(1, 0, 0,-M_PI_2);
    earthOrbit.geometry.firstMaterial.lightingModelName = SCNLightingModelConstant; // no lighting
    earthOrbit.geometry.firstMaterial.doubleSided = YES;
    //添加到太阳节点上
    [_sunNode addChildNode:earthOrbit];
}

- (void)addLightToSun {
    // We will turn off all the lights in the scene and add a new light
    // to give the impression that the Sun lights the scene
    // 关闭场景中所有光源并添加一个新光源,来模拟场景中的太阳光
    SCNNode *lightNode = [SCNNode node];
    lightNode.light = [SCNLight light];
    lightNode.light.color = [UIColor blackColor]; // initially switched off
    lightNode.light.type = SCNLightTypeOmni;
    [_sunNode addChildNode:lightNode];
    
    // Configure attenuation distances because we don't want to light the floor
    // 配置光源衰减距离
    lightNode.light.attenuationEndDistance = 20.0;
    lightNode.light.attenuationStartDistance = 19.5;
    
    // 动画
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:1];
    {
        lightNode.light.color = [UIColor whiteColor]; // switch on
        //[presentationViewController updateLightingWithIntensities:@[@0.0]]; //switch off all the other lights
        _sunHaloNode.opacity = 0.5; // make the halo stronger
    }
    [SCNTransaction commit];
}
- (void)addHaloToSun {
    //太阳光晕节点
    _sunHaloNode = [SCNNode node];
    _sunHaloNode.geometry = [SCNPlane planeWithWidth:100 height:100];
    _sunHaloNode.rotation = SCNVector4Make(1, 0, 0,  0.5* M_PI);
    _sunHaloNode.geometry.firstMaterial.diffuse.contents = @"art.scnassets/earth/sun-halo.png";
    _sunHaloNode.geometry.firstMaterial.lightingModelName = SCNLightingModelConstant; // no lighting
    _sunHaloNode.geometry.firstMaterial.writesToDepthBuffer = NO; // do not write to depth
    _sunHaloNode.opacity = 0.1;
    _sunHaloNode.geometry.firstMaterial.doubleSided = YES;
    //添加到太阳节点上(暂时放弃)
    [_sunNode addChildNode:_sunHaloNode];
}

- (void)addAnimationToSun {
    // 给太阳添加动态熔岩纹理
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"contentsTransform"];
    animation.duration = 10.0;
    animation.fromValue = [NSValue valueWithCATransform3D:CATransform3DConcat(CATransform3DMakeTranslation(0, 0, 0), CATransform3DMakeScale(3, 3, 3))];
    animation.toValue = [NSValue valueWithCATransform3D:CATransform3DConcat(CATransform3DMakeTranslation(1, 0, 0), CATransform3DMakeScale(3, 3, 3))];
    animation.repeatCount = FLT_MAX;
    [_sunNode.geometry.firstMaterial.diffuse addAnimation:animation forKey:@"sun-texture"];
    
    animation = [CABasicAnimation animationWithKeyPath:@"contentsTransform"];
    animation.duration = 30.0;
    animation.fromValue = [NSValue valueWithCATransform3D:CATransform3DConcat(CATransform3DMakeTranslation(0, 0, 0), CATransform3DMakeScale(5, 5, 5))];
    animation.toValue = [NSValue valueWithCATransform3D:CATransform3DConcat(CATransform3DMakeTranslation(1, 0, 0), CATransform3DMakeScale(5, 5, 5))];
    animation.repeatCount = FLT_MAX;
    [_sunNode.geometry.firstMaterial.multiply addAnimation:animation forKey:@"sun-texture2"];
}

//数学公式旋转,暂时无用,仅供学习
- (void)mathRoation {
    // 相关数学知识点： 任意点a(x,y)，绕一个坐标点b(rx0,ry0)逆时针旋转a角度后的新的坐标设为c(x0, y0)，有公式：
    //    x0= (x - rx0)*cos(a) - (y - ry0)*sin(a) + rx0 ;
    //    y0= (x - rx0)*sin(a) + (y - ry0)*cos(a) + ry0 ;
    // custom Action
    float totalDuration = 10.0f;        //10s 围绕地球转一圈
    float duration = totalDuration/360;  //每隔duration秒去执行一次
    
    SCNAction *customAction = [SCNAction customActionWithDuration:duration actionBlock:^(SCNNode * _Nonnull node, CGFloat elapsedTime){
        if(elapsedTime==duration){
            SCNVector3 position = node.position;
            
            float rx0 = 0;    //原点为0
            float ry0 = 0;
            
            float angle = 1.0f/180*M_PI;
            float x =  (position.x - rx0)*cos(angle) - (position.z - ry0)*sin(angle) + rx0 ;
            float z = (position.x - rx0)*sin(angle) + (position.z - ry0)*cos(angle) + ry0 ;
            node.position = SCNVector3Make(x, node.position.y, z);
        }
    }];
    
    SCNAction *repeatAction = [SCNAction repeatActionForever:customAction];
    [_earthGroupNode runAction:repeatAction];
}
#pragma mark 调用方法

/**
 矩阵变换操作
 */
-(void)changeProjection4Matrix {
    //如果识别出图片,且需要显示星球模型,则显示
    if (self.glView.isTracked && self.glView.shouldShowStar) {
        self.sunNode.hidden = NO;
    }else {
        self.sunNode.hidden = YES;
    }
    
    SCNMatrix4 p = self.glView.projection4Matrix;
    SCNMatrix4 c = self.glView.cameraview4Matrix;
    
    NSLog(@"cameraview4Matrix--\n%lf,%lf,%lf,%lf,\n%lf,%lf,%lf,%lf,\n%lf,%lf,%lf,%lf,\n%lf,%lf,%lf,%lf\n",c.m11,c.m12,c.m13,c.m14,c.m21,c.m22,c.m23,c.m24,c.m31,c.m32,c.m33,c.m34,c.m41,c.m42,c.m43,c.m44);
    //NSLog(@"projection4Matrix--\n%lf,%lf,%lf,%lf,\n%lf,%lf,%lf,%lf,\n%lf,%lf,%lf,%lf,\n%lf,%lf,%lf,%lf\n",p.m11,p.m12,p.m13,p.m14,p.m21,p.m22,p.m23,p.m24,p.m31,p.m32,p.m33,p.m34,p.m41,p.m42,p.m43,p.m44);
    
    self.sunNode.transform = c;
    //self.earthRotationNode.transform = c;
    
}

/**
 点击scnView中各子节点,显示红色高亮
 
 @param gestureRecognize 点击手势
 */
- (void) handleTap:(UIGestureRecognizer*)gestureRecognize
{
    // 点击了哪个组件
    CGPoint p = [gestureRecognize locationInView:_scnView];
    NSArray *hitResults = [_scnView hitTest:p options:nil];
    
    // check that we clicked on at least one object
    if([hitResults count] > 0){
        // 拿到点击处最近的对象
        SCNHitTestResult *result = [hitResults objectAtIndex:0];
        // 拿到对象的材质
        SCNMaterial *material = result.node.geometry.firstMaterial;
        
        // 高亮,延时0.5s
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:0.5];
        // on completion - unhighlight
        [SCNTransaction setCompletionBlock:^{
            [SCNTransaction begin];
            [SCNTransaction setAnimationDuration:0.5];
            material.emission.contents = [UIColor blackColor];
            [SCNTransaction commit];
        }];
        
        material.emission.contents = [UIColor redColor];
        
        [SCNTransaction commit];
    }
}

#pragma mark SCNSceneRendererDelegate
- (void)renderer:(id <SCNSceneRenderer>)renderer updateAtTime:(NSTimeInterval)time {
    [self changeProjection4Matrix];
}
#pragma mark 界面旋转横屏
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    [self.glView setOrientation:toInterfaceOrientation];
}

@end
