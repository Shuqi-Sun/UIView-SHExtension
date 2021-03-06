//
//  SHEmotionKeyboard.m
//  SHEmotionKeyboardUI
//
//  Created by CSH on 2016/12/7.
//  Copyright © 2016年 CSH. All rights reserved.
//

#import "SHEmotionKeyboard.h"
#import "UIView+SHExtension.h"
#import "SHEmotionModel.h"
#import "UIButton+RemoveHighlightEffect.h"
#import "SHEmotionTool.h"
#import "SHMessageMacroHeader.h"

#define EmotionRGB(r,g,b) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]

#pragma mark - 表情按钮SHEmotionButton
@class SHEmotionModel;

@interface SHEmotionButton : UIButton

//当前button显示的emotion
@property (nonatomic, strong) SHEmotionModel *emotion;
//其他
@property (nonatomic, strong) UIImage *image;

@property (nonatomic, strong) UIButton *deleteButton;

@end

@implementation SHEmotionButton

#pragma mark - 懒加载
- (UIButton *)deleteButton{
    if (!_deleteButton) {
        //删除按钮（收藏用）
        _deleteButton = [[UIButton alloc] init];
        
        //设置图片
        [_deleteButton setImage:[SHEmotionTool emotionImageWithName:@"compose_photo_close"] forState:UIControlStateNormal];
        //设置大小
        _deleteButton.size = [_deleteButton currentImage].size;
        
        _deleteButton.hidden = YES;
        
        [_deleteButton addTarget:self action:@selector(deleteBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:_deleteButton];
    }
    return _deleteButton;
}

#pragma mark - 收藏删除点击
- (void)deleteBtnClick:(UIButton *)button{
    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 0.0;
        [SHEmotionTool delectCollectImageWithModel:self.emotion];
    } completion:^(BOOL finished) {
        //动画执行完毕,移除
        [self removeFromSuperview];
        
    }];
}

#pragma mark - 长按收藏图片
-(void)longTap:(UILongPressGestureRecognizer *)longRecognizer
{
    //控制连续点击
    if (longRecognizer.state == UIGestureRecognizerStateBegan) {
        NSLog(@"长按收藏图片");
        self.deleteButton.hidden = NO;
    }
}

#pragma mark - SET
- (void)setEmotion:(SHEmotionModel *)emotion{
    _emotion = emotion;
    
    //设置按钮内容
    switch (emotion.type) {
        case SHEmoticonType_gif://GIF
        {
            _emotion.path = [kGif_Emoji_Path stringByAppendingString:emotion.png];
            //设置表情图片
            UIImage *image = [UIImage imageWithContentsOfFile:_emotion.path];
            [self setImage:image forState:UIControlStateNormal];
        }
            break;
        case SHEmoticonType_custom://自定义
        {
            _emotion.path = [kCustom_Emoji_Path stringByAppendingString:emotion.png];
            //设置表情图片
            UIImage *image = [UIImage imageWithContentsOfFile:_emotion.path];
            [self setImage:image forState:UIControlStateNormal];
        }
            break;
        case SHEmoticonType_system://系统
        {
            _emotion.path = [emotion.code emoji];
            [self setTitle:_emotion.path forState:UIControlStateNormal];
        }
            break;
        case SHEmoticonType_collect://收藏
        {
            _emotion.path = [kCollect_Emoji_Path stringByAppendingPathComponent:emotion.png];
            //设置图片
            [self setImage:[UIImage imageWithContentsOfFile:_emotion.path] forState:UIControlStateNormal];
            
            //设置内距
            [self setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
            
            if (self.tag == SHEmoticonType_collect) {//如果当前接界面为收藏界面则添加长按
                //添加长按手势
                UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longTap:)];
                longPress.minimumPressDuration = 0.5;//最小点按时间
                [self addGestureRecognizer:longPress];
            }
        }
            break;
        default:
            break;
    }

}

- (void)setImage:(UIImage *)image{
    _image = image;
    [self setImage:image forState:UIControlStateNormal];
}

@end

#pragma mark - 工具栏SHEmotionToolBar
@class SHEmotionToolBar;

@protocol SHEmotionToolBarDelegate <NSObject>

- (void)emotionToolbar:(SHEmotionToolBar *)toolBar buttonClickWithType:(SHEmoticonType)type;

@end

@interface SHEmotionToolBar : UIView

@property (nonatomic, weak) id<SHEmotionToolBarDelegate> delegate;

@property (nonatomic, strong) NSArray *toolArr;

- (void)setup;

@end

@interface SHEmotionToolBar()

//下方按钮滚动视图
@property (nonatomic, weak) UIScrollView *emotionScroll;
//当前选中的button
@property (nonatomic, weak) UIButton *currentBtn;
//自定义按钮
@property (nonatomic, weak) UIButton *customBtn;
//系统按钮
@property (nonatomic, weak) UIButton *systemBtn;
//gif按钮
@property (nonatomic, weak) UIButton *gifBtn;
//收藏按钮
@property (nonatomic, weak) UIButton *collectBtn;
//最近按钮
@property (nonatomic, weak) UIButton *recentBtn;

@end

@implementation SHEmotionToolBar

//下方工具栏最多按钮个数
#define ToolMaxNum 5

#pragma mark - 懒加载
- (UIScrollView *)emotionScroll{
    
    if (!_emotionScroll) {
        UIScrollView *emotionScroll = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, (ToolMaxNum - 1)*self.width/ToolMaxNum, self.height)];
        //隐藏水平方向的滚动条
        emotionScroll.showsHorizontalScrollIndicator = NO;
        emotionScroll.showsVerticalScrollIndicator = NO;
        [self addSubview:emotionScroll];
        
        _emotionScroll = emotionScroll;
    }
    return _emotionScroll;
}

#pragma mark - 设置
- (void)setup{
    
    //设置背景
    self.backgroundColor = [UIColor whiteColor];
    
    self.emotionScroll.contentSize = CGSizeMake(self.toolArr.count*self.width/ToolMaxNum, self.height);
    
    [self.toolArr enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        switch ([obj intValue]) {
            case SHEmoticonType_collect://收藏
            {
                self.collectBtn = [self addChildBtnWithTitle:@"收藏" bgImageName:@"emoticon_keyboard_background" type:SHEmoticonType_collect Index:idx];
            }
                break;
            case SHEmoticonType_custom://自定义
            {
                self.customBtn = [self addChildBtnWithTitle:@"默认" bgImageName:@"emoticon_keyboard_background" type:SHEmoticonType_custom Index:idx];
            }
                break;
            case SHEmoticonType_system://系统
            {
                self.systemBtn = [self addChildBtnWithTitle:@"系统" bgImageName:@"emoticon_keyboard_background" type:SHEmoticonType_system Index:idx];
            }
                break;
            case SHEmoticonType_gif://GIF
            {
                self.gifBtn = [self addChildBtnWithTitle:@"GIF" bgImageName:@"emoticon_keyboard_background" type:SHEmoticonType_gif Index:idx];
            }
                break;
            case SHEmoticonType_recent://最近
            {
                self.recentBtn = [self addChildBtnWithTitle:@"最近" bgImageName:@"emoticon_keyboard_background" type:SHEmoticonType_recent Index:idx];
            }
                break;
        }
    }];
    
    //最后添加一个设置发送按钮
    UIButton *sendBtn = [[UIButton alloc]initWithFrame:CGRectMake(self.emotionScroll.maxX, 0, self.width/ToolMaxNum, self.height)];
    sendBtn.tag = 100;
    [sendBtn setTitle:@"发送" forState:UIControlStateNormal];
    [sendBtn setBackgroundColor:[UIColor orangeColor]];
    [sendBtn addTarget:self action:@selector(sendBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:sendBtn];
    
    //点击一下第一个按钮
    if (self.toolArr.count) {
        //默认点击第一个
        [self childButtonClick:(UIButton *)[self viewWithTag:[self.toolArr[0] intValue]]];
    }
}

- (UIButton *)addChildBtnWithTitle:(NSString *)title bgImageName:(NSString *)bgImageName type:(SHEmoticonType)type Index:(NSInteger)index{
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    button.frame = CGRectMake(index*self.width/5, 0, self.width/5, self.height);
    button.tag = type;
    
    //设置标题
    [button setTitle:title forState:UIControlStateNormal];
    
    //设置下方工具栏按钮颜色
    [button setBackgroundColor:[UIColor whiteColor]];
    [button setBackgroundImage:[SHEmotionTool emotionImageWithName:bgImageName] forState:UIControlStateDisabled];
    
    //设置未选中状态字体颜色
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    //设置选中状态字体颜色
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    
    //监听点击事件
    [button addTarget:self action:@selector(childButtonClick:) forControlEvents:UIControlEventTouchDown];
    
    //添加到界面
    [self.emotionScroll addSubview:button];
    
    return button;
}

#pragma mark - scroll滑动最后一页
- (void)scrollviewLastPage:(NSNotification *)notify{
    
//    SHEmotionKeyboard *emotionKeyboard = [SHEmotionKeyboard sharedSHEmotionKeyboard];
//    //为数组最后一个
//    if ([notify.object intValue] == [[emotionKeyboard.toolBarArr lastObject] intValue]) {
//        //默认点击第一个
//        [self childButtonClick:(UIButton *)[self viewWithTag:[emotionKeyboard.toolBarArr[0] intValue]]];
//    }
//
//    [self childButtonClick:(UIButton *)[self viewWithTag:[notify.object intValue]]];
}

#pragma mark - 下方工具栏点击
- (void)childButtonClick:(UIButton *)button{
    
    //先移除之前选中的button
    self.currentBtn.enabled = YES;
    //选中当前
    button.enabled = NO;
    //记录当前选中的按钮
    self.currentBtn = button;
    
    if ([self.delegate respondsToSelector:@selector(emotionToolbar:buttonClickWithType:)]) {
        [self.delegate emotionToolbar:self buttonClickWithType:button.tag];
    }
}

#pragma mark - 下方按钮发送点击
- (void)sendBtnClick:(UIButton *)btn{
    
    [[NSNotificationCenter defaultCenter]postNotificationName:@"EmotionSendBtnSelectedNoti" object:nil];
}

@end

#pragma mark - 滚动视图SHEmotionPageView

@interface SHEmotionPageView : UIView
/**
 *  当前一页对应的表情集合
 */
@property (nonatomic, strong) NSArray *emotions;

@end

#define MARGIN 10

@interface SHEmotionPageView()

//表情按钮对应的集合,记录表情按钮,以便在调整位置的时候用到
@property (nonatomic, strong) NSMutableArray *emotionButtons;

@end

@implementation SHEmotionPageView
{
    NSInteger  _page_max_col;
    NSInteger  _page_max_row;
}

- (NSMutableArray *)emotionButtons{
    if (!_emotionButtons) {
        _emotionButtons = [NSMutableArray array];
    }
    return _emotionButtons;
}

- (void)setEmotions:(NSArray *)emotions{
    
    _emotions = emotions;

    switch (self.tag) {//设置当前界面排序
        case SHEmoticonType_gif://GIF排序4*2
        {
            _page_max_col = 4;
            _page_max_row = 2;
        }
            break;
        default://其他7*3
        {
            _page_max_col = 7;
            _page_max_row = 3;
        }
            break;
    }
    
    [emotions enumerateObjectsUsingBlock:^(SHEmotionModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        SHEmotionButton *button = [[SHEmotionButton alloc] init];
        //将当前界面类型给上方的Btn
        button.tag = self.tag;
        button.titleLabel.font = [UIFont systemFontOfSize:35];
        button.emotion = obj;
    
        //按钮点击监听
        [button addTarget:self action:@selector(emotionButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:button];
        
        [self.emotionButtons addObject:button];
    }];
    
}

/**
 *  表情点击
 *
 *  @param button <#button description#>
 */
- (void)emotionButtonClick:(SHEmotionButton *)button{
    
    //发出表情点击了的通知
    [[NSNotificationCenter defaultCenter]postNotificationName:@"EmotionDidSelectedNoti" object:button];
}

#pragma mark - 自动绘制界面
- (void)layoutSubviews{
    [super layoutSubviews];

    //取出子控件的个数
    NSInteger count = self.emotionButtons.count;
    
    CGFloat childW = (self.width - MARGIN) / _page_max_col;
    CGFloat childH = (self.height - MARGIN) / _page_max_row;
    
    for (int i = 0; i < count; i++) {
        UIView *view = self.emotionButtons[i];
        
        view.size = CGSizeMake(childW, childH);
        
        //求出当前在第几列第几行
        NSInteger col = i % _page_max_col;
        NSInteger row = i / _page_max_col;
        
        //设置位置
        view.x = col * childW + MARGIN;
        view.y = row * childH + MARGIN;
    }
}

@end

#pragma mark - 列表SHEmotionListView

@interface SHEmotionListView : UIView
/**
 *  当前ListView对应的表情集合
 */
@property (nonatomic, strong) NSArray *emotions;

@property (nonatomic, assign) SHEmoticonType currentType;

@end

@interface SHEmotionListView()<UIScrollViewDelegate>

//page
@property (nonatomic, weak) UIPageControl *pageControl;
//滚动视图
@property (nonatomic, weak) UIScrollView *scrollView;

//记录scrollView的用户自己添加的子控件,因为直接调用 scrollView.subViews会出现问题(因为滚动条也算scrollView的子控件)
@property (nonatomic, strong) NSMutableArray *scrollsubViews;

@end

@implementation SHEmotionListView

#pragma mark - 懒加载
- (NSMutableArray *)scrollsubViews{
    if (!_scrollsubViews) {
        _scrollsubViews = [NSMutableArray array];
    }
    return _scrollsubViews;
}

- (UIScrollView *)scrollView{
    if (!_scrollView) {
    
        //添加scrollView
        UIScrollView *scrollView = [[UIScrollView alloc] init];
        //隐藏水平方向的滚动条
        scrollView.showsHorizontalScrollIndicator = false;
        scrollView.showsVerticalScrollIndicator = false;
        //开启分页
        scrollView.pagingEnabled = YES;
        
        //设置代理
        scrollView.delegate = self;
        
        [self addSubview:scrollView];
        _scrollView = scrollView;
    }
    return _scrollView;
}

- (UIPageControl *)pageControl{
    if (!_pageControl) {
        //添加uipageControl
        UIPageControl *control = [[UIPageControl alloc] init];
        control.userInteractionEnabled = NO;
        [control setCurrentPageIndicatorTintColor:EmotionRGB(134, 134, 134)];
        [control setPageIndicatorTintColor:EmotionRGB(180, 180, 180)];
        
        [self addSubview:control];
        _pageControl = control;
    }
    return _pageControl;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    //设置pageControl
    self.pageControl.width = self.width;
    self.pageControl.height = 30;
    
    self.pageControl.y = self.height - self.pageControl.height;
    
    //设置scrollView
    self.scrollView.width = self.width;
    self.scrollView.height = self.pageControl.y;
    
    //设置scrollView里面子控件的大小
    for (int i=0; i<self.scrollsubViews.count; i++) {
        UIView *view = self.scrollsubViews[i];
        
        view.size = self.scrollView.size;
        view.x = i * self.scrollView.width;
    }
    
    //根据添加的子控件的个数计算内容大小
    self.scrollView.contentSize = CGSizeMake(self.scrollView.width * self.scrollsubViews.count, self.scrollView.height);
}

- (void)setEmotions:(NSArray *)emotions{
    
    _emotions = emotions;
    
    [self.scrollView scrollsToTop];
    
    //在第二次执行这个方法的时候,就需要把之前已经添加的pageView给移除
    [self.scrollsubViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.scrollsubViews removeAllObjects];
    
    //计算一页最多多少个
    NSInteger pageMaxEmotionCount = (self.currentType == SHEmoticonType_gif)?(2*4):(7*3);
    //根据个数计算出多少页
    
    //(总数+每一页的个数-1)/每一页的个数
    NSInteger page = (emotions.count + pageMaxEmotionCount - 1 )/ pageMaxEmotionCount ;
    
    //设置页数
    self.pageControl.numberOfPages = page;
    
    for (int i = 0; i < page; i++) {
        
        SHEmotionPageView *view = [[SHEmotionPageView alloc] init];
        view.tag = self.currentType;
        //切割每一页的表情集合
        NSRange range;
        
        range.location = i * pageMaxEmotionCount;
        range.length = pageMaxEmotionCount;
        
        //如果表情只有99个,那么最后一页就不满20个,所以需要加一个判断
        NSInteger lastPageCount = emotions.count - range.location;
        if (lastPageCount < pageMaxEmotionCount) {
            range.length = lastPageCount;
        }
        
        //截取出来是每一页对应的表情
        NSArray *childEmotions = [emotions subarrayWithRange:range];
        //设置每一页的表情集合
        view.emotions = childEmotions;
        
        [self.scrollView addSubview:view];
        [self.scrollsubViews addObject:view];
    }
    
    //告诉当前控件,去重新布局一下
    [self setNeedsLayout];
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    //计算页数-->小数-->四舍五入
    CGFloat page = scrollView.contentOffset.x / scrollView.width;
    self.pageControl.currentPage = (int)(page + 0.5);
    
//    if (scrollView.contentSize.width < scrollView.contentOffset.x + scrollView.width) {
//        if (_currentType == [[self.toolArr lastObject] intValue]) {
//            _currentType = 100;
//        }
//        [scrollView scrollRectToVisible:CGRectMake(0, 0, scrollView.width, scrollView.height) animated:NO];
//        [[NSNotificationCenter defaultCenter]postNotificationName:@"scrollviewLastPage" object:[NSString stringWithFormat:@"%d", (int)_currentType + 1]];
//    }
}

@end

#pragma mark - SHEmotionKeyboard

@interface SHEmotionKeyboard()<SHEmotionToolBarDelegate>

//下方工具栏
@property (nonatomic, strong) SHEmotionToolBar *toolBar;

//当前
@property (nonatomic, strong) SHEmotionListView *currentListView;

//收藏
@property (nonatomic, strong) SHEmotionListView *collectListView;

//自定义
@property (nonatomic, strong) SHEmotionListView *customListView;

//系统
@property (nonatomic, strong) SHEmotionListView *systemListView;

//GIF
@property (nonatomic, strong) SHEmotionListView *gifListView;

//最近
@property (nonatomic, strong) SHEmotionListView *recentListView;

@end

@implementation SHEmotionKeyboard

//+ (instancetype)sharedSHEmotionKeyboard{
//    static SHEmotionKeyboard *view;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        if (!view) {
//            view = [[self alloc]init];
//        }
//    });
//    return view;
//}

#pragma mark - 设置
- (void)reloadView{
    //设置颜色
    self.backgroundColor = EmotionRGB(243, 243, 247);
    
    //表情点击通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(emotionDidSelected:) name:@"EmotionDidSelectedNoti" object:nil];
    //发送点击通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(emotionSendBtnSelected) name:@"EmotionSendBtnSelectedNoti" object:nil];
    //删除收藏图片通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(delectCollectImage) name:@"delectCollectImage" object:nil];
    
    //初始化
    self.toolBar = nil;
    
    //工具栏上方添加分割线
    UIView *line = [[UIView alloc]initWithFrame:CGRectMake(0, self.height - 37, self.width , 0.6)];
    line.backgroundColor = EmotionRGB(225, 225, 225);
    [self addSubview:line];
}

#pragma mark - 懒加载
#pragma mark 下方工具栏
- (SHEmotionToolBar *)toolBar{
    if (!_toolBar) {
        //设置下方工具栏
        _toolBar = [[SHEmotionToolBar alloc] initWithFrame:CGRectMake(0, 0, self.width, 37)];
        _toolBar.delegate = self;
        _toolBar.toolArr = self.toolBarArr;
        [_toolBar setup];
        [self addSubview:_toolBar];
    }
    return _toolBar;
}

#pragma mark 上方收藏表情视图
- (SHEmotionListView *)collectListView{
    if (!_collectListView) {
        _collectListView = [[SHEmotionListView alloc] init];
        _collectListView.currentType = SHEmoticonType_collect;
    }
    _collectListView.emotions = [SHEmotionTool collectEmotions];
    return _collectListView;
}

#pragma mark 上方自定义表情视图
- (SHEmotionListView *)customListView{
    if (!_customListView) {
        _customListView = [[SHEmotionListView alloc] init];
        _customListView.currentType = SHEmoticonType_custom;
        _customListView.emotions = [SHEmotionTool customEmotions];
    }
    return _customListView;
}

#pragma mark 上方系统表情视图
- (SHEmotionListView *)systemListView{
    if (!_systemListView) {
        _systemListView = [[SHEmotionListView alloc] init];
        _systemListView.currentType = SHEmoticonType_system;
        _systemListView.emotions = [SHEmotionTool systemEmotions];
    }
    return _systemListView;
}

#pragma mark 上方GIF表情视图
- (SHEmotionListView *)gifListView{
    if (!_gifListView) {
        _gifListView = [[SHEmotionListView alloc]init];
        _gifListView.currentType = SHEmoticonType_gif;
        _gifListView.emotions = [SHEmotionTool gifEmotions];
    }
    return _gifListView;
}

#pragma mark 上方最近表情视图
- (SHEmotionListView *)recentListView{
    if (!_recentListView) {
        _recentListView = [[SHEmotionListView alloc]init];
        _recentListView.currentType = SHEmoticonType_recent;
    }
    _recentListView.emotions = [SHEmotionTool recentEmotions];
    return _recentListView;
}

#pragma mark - EmotionKeyboard代理方法
#pragma mark 表情选中
- (void)emotionDidSelected:(NSNotification *)noti{
    
    SHEmotionButton *button = noti.object;
    
    NSString *text = nil;
    //设置显示文字
    switch (button.emotion.type) {
        case SHEmoticonType_system://系统
            text = button.titleLabel.text;
            break;
        case SHEmoticonType_collect://收藏
            text = button.emotion.code;
            break;
        default:
            text = button.emotion.chs;
            break;
    }
    
    //如果有最近功能需要进行添加
    for (NSString *obj in self.toolBarArr) {
        if ([obj intValue] == SHEmoticonType_recent) {//如果有最近则进行添加
            //添加到最近
            [SHEmotionTool addRecentEmotion:button.emotion];
            break;
        }
    }
    
    //进行代理通知
    if ([_delegate respondsToSelector:@selector(emoticonInputWithText:Model:isSend:)]) {
        
        switch (button.emotion.type) {
            case SHEmoticonType_gif://Gif
            case SHEmoticonType_collect://收藏
            {
                //直接进行发送
                [_delegate emoticonInputWithText:text Model:button.emotion isSend:YES];
            }
                break;
            default:
            {
                [_delegate emoticonInputWithText:text Model:button.emotion isSend:NO];
            }
                break;
        }
    }
}

#pragma mark - 发送按钮点击
- (void)emotionSendBtnSelected{
    
    if ([self.delegate respondsToSelector:@selector(emoticonInputSend)]) {
        [[UIDevice currentDevice] playInputClick];
        [self.delegate emoticonInputSend];
    }
}

#pragma mark - 删除收藏图片按钮点击
- (void)delectCollectImage{
    
    [self emotionToolbar:self.toolBar buttonClickWithType:SHEmoticonType_collect];
}

#pragma mark - 更新视图
- (void)layoutSubviews{
    [super layoutSubviews];
    
    //设置toolBar宽度与y
    self.toolBar.y = self.height - self.toolBar.height;
    self.toolBar.width = self.width;
    
    //调整当前要显示的listView的位置与大小
    self.currentListView.width = self.width;
    self.currentListView.height = self.toolBar.y;
}

#pragma mark - EmotionToolBar delegate 方法
- (void)emotionToolbar:(SHEmotionToolBar *)toolBar buttonClickWithType:(SHEmoticonType)type{
    
    //先移除原来显示的
    [self.currentListView removeFromSuperview];
    
    //更新一下视图
    switch (type) {
        case SHEmoticonType_collect://收藏
            [self addSubview:self.collectListView];
            break;
        case SHEmoticonType_custom://自定义
            [self addSubview:self.customListView];
            break;
        case SHEmoticonType_system://系统
            [self addSubview:self.systemListView];
            break;
        case SHEmoticonType_gif://GIF
            [self addSubview:self.gifListView];
            break;
        case SHEmoticonType_recent://最近
            [self addSubview:self.recentListView];
            break;
    }

    //再赋值当前显示的listView
    self.currentListView = [self.subviews lastObject];
}

#pragma mark - 销毁
- (void)dealloc{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
