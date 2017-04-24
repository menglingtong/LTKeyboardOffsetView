//
//  UIView+LTKeyboardOffsetView.h
//  LTTimeControl
//
//  Created by 孟令通 on 17/3/6.
//  Copyright © 2017年 LryMlt. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kLTDatePickerShow @"LTDatePickerShow"

#define kLTDatePickerHide @"LTDatePickerHide"

@protocol LTKeyboardOffsetViewDelegate <NSObject>

@required
/**
 *  弹出键盘时，自定义视图向上移动的高度
 *
 *  @param firstResponder 第一响应者
 *  @param keyboardHeight 当前弹出键盘的高度
 *  @param offsetHeight   默认偏移高度
 *
 *  @return 视图向上移动的高度
 */
- (CGFloat)offsetHeightWithFirstResponder:(UIView *)firstResponder
                           keyboardHeight:(CGFloat)keyboardHeight
                             offsetHeight:(CGFloat)offsetHeight;

@end

/* 键盘补偿工具，避免键盘遮挡输入框 */
@interface UIView (LTKeyboardOffsetView)

/** 键盘与第一响应者的缝隙，默认6.0 */
@property (nonatomic, assign) CGFloat keyboardGap;

@property (nonatomic, weak) id<LTKeyboardOffsetViewDelegate> ltKeyboardOffsetViewDelegate;

- (void)openKeyboardOffsetView;

- (void)closeKeyboardOffsetView;

@end
