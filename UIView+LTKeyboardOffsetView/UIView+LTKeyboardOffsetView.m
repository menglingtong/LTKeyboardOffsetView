//
//  UIView+LTKeyboardOffsetView.m
//  LTTimeControl
//
//  Created by 孟令通 on 17/3/6.
//  Copyright © 2017年 LryMlt. All rights reserved.
//

#import "UIView+LTKeyboardOffsetView.h"

#import <objc/runtime.h>

@implementation UIView (LTKeyboardOffsetView)

static char kkeyboardGap;

static char kltKeyboardOffsetViewDelegate;



// 由于类目不可以直接添加属性，我们可以通过 runtime 的 objc_setAssociatedObject 为 UIView 动态添加属性，和类进行关联
- (void)setKeyboardGap:(CGFloat)keyboardGap
{
    objc_setAssociatedObject(self, &kkeyboardGap, [NSNumber numberWithFloat:keyboardGap], OBJC_ASSOCIATION_RETAIN);
}

- (CGFloat)keyboardGap
{
    if (objc_getAssociatedObject(self, &kkeyboardGap) == nil) {
        return 6.0;
    }
    
    return [objc_getAssociatedObject(self, &kkeyboardGap) floatValue];
}

- (void)setLtKeyboardOffsetViewDelegate:(id<LTKeyboardOffsetViewDelegate>)ltKeyboardOffsetViewDelegate
{
    objc_setAssociatedObject(self, &kltKeyboardOffsetViewDelegate, ltKeyboardOffsetViewDelegate, OBJC_ASSOCIATION_RETAIN);
}

- (id<LTKeyboardOffsetViewDelegate>)ltKeyboardOffsetViewDelegate
{
    return objc_getAssociatedObject(self, &kltKeyboardOffsetViewDelegate);
}

// 打开键盘补偿视图
- (void)openKeyboardOffsetView
{
    
    //对系统的某些事件时作出响应只要注册一个观察者即可
    //事件1：每次键盘显示后得到通知就得关心 UIKeyboardDidShowNotification 事件:这里的post是系统自己定义好的，不需要写，只需要添加自己是观察者，且做出相应就可以，观察者名字是系统的，记得不观察的时候要移除监听观察者事件
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillAppear:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillDisappear:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(datePickerWillAppear:)
                                                 name:kLTDatePickerShow
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(datePickerWillDisappear:)
                                                 name:kLTDatePickerHide
                                               object:nil];
    
}

// 关闭键盘补偿视图
- (void)closeKeyboardOffsetView
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLTDatePickerShow object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLTDatePickerHide object:nil];
}

/* 获得键盘高度 */
/**
 *  convertRect
 *
 *  [A convertRect:B.frame  toView:C];   // 计算A上的B视图在C中的位置CGRect
 *  [A convertRect:B.frame  fromView:C]; // 计算C上的B视图在A中的位置CGRect
 *
 *  convertPoint
 *
 *  [A convertPoint:B.center toView:C];  // 计算A上的B视图在C中的位置CGPoint
 *  [A convertPoint:B.center fromView:C];// 计算C上的B视图在A中的位置CGPoint
 *
 */
- (CGFloat)keyboardFrameHeight:(NSDictionary *)userInfo
{
    CGRect keyboardUncorrectedFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardFrame = [self convertRect:keyboardUncorrectedFrame fromView:nil];
    return keyboardFrame.size.height;
}

- (UIView *)firstResponder
{
    if ([self isKindOfClass:[UITextField class]] || [self isKindOfClass:[UITextView class]]) {
        
        if (self.isFirstResponder) {
            
            return self;
        }
        else
        {
            return nil;
        }
        
    }
    
    NSArray *subView = [self subviews];
    
    if (subView.count == 0) {
        return nil;
    }
    
    for (UIView *responder in subView) {
        
        UIView *firstResponder = [responder firstResponder];
        
        if (firstResponder.isFirstResponder) {
            
            return firstResponder;
        }
        
    }
    
    return nil;
}

- (void)keyboardWillAppear:(NSNotification *)notification
{
//    NSLog(@"%@", [notification userInfo]);
    
    // 获取键盘高度
    CGFloat keyboardHeight = [self keyboardFrameHeight:[notification userInfo]];
    
    // 获取键盘弹出持续时间
    CGFloat duration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    // 键盘弹出动画的时间曲线
    UIViewAnimationOptions options = [[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16;
    
    // 获取第一响应者的位置
    UIView *firstResponder = [self firstResponder];
    CGRect rect = [firstResponder.superview convertRect:firstResponder.frame toView:self];
    
    // 计算向上偏移的高度，根据当前的第一响应者计算视图偏移高度，当键盘没有遮挡输入框时，弹出键盘时不需要移动视图
    CGFloat offsetViewHeight = self.frame.size.height - rect.origin.y - rect.size.height - self.keyboardGap;
    if (keyboardHeight < offsetViewHeight)
        offsetViewHeight = 0;
    else
        offsetViewHeight = keyboardHeight - offsetViewHeight;
    
    // 通过代理获取视图偏移的高度
    if([self.ltKeyboardOffsetViewDelegate respondsToSelector:@selector(offsetHeightWithFirstResponder:keyboardHeight:offsetHeight:)])
    {
        offsetViewHeight  = [self.ltKeyboardOffsetViewDelegate offsetHeightWithFirstResponder:firstResponder
                                                                               keyboardHeight:keyboardHeight
                                                                                 offsetHeight:offsetViewHeight];
    }
    
    // 避免循环引用
    __weak typeof(self) weakSelf = self;
    
    // 执行向上移动视图的动画
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:options
                     animations:^{
                         // 动画执行代码
                         weakSelf.transform = CGAffineTransformMakeTranslation(0, -offsetViewHeight);
                     }
                     completion:^(BOOL completed) {
                         // 动画结束后执行的代码
                     }];
}

- (void)keyboardWillDisappear:(NSNotification *)notification
{
    CGFloat duration = [[notification userInfo][UIKeyboardAnimationDurationUserInfoKey] floatValue];    // 动画持续时间
    UIViewAnimationOptions options = [[notification userInfo][UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16; // 动画时间曲线
    
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:options
                     animations:^{
                         // 动画执行代码
                         self.transform = CGAffineTransformIdentity;
                     }
                     completion:^(BOOL completed) {
                         // 动画结束后执行的代码
                     }];
}

- (void)datePickerWillAppear:(NSNotification *)notification
{
//    NSLog(@"%@", [[notification userInfo] objectForKey:@"datePickerHeight"]);
}

- (void)datePickerWillDisappear:(NSNotification *)notification
{
    
}



@end
