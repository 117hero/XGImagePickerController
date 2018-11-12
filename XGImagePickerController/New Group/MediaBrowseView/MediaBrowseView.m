//
//  MediaBrowseView.m
//  MyApp
//
//  Created by huxinguang on 2018/10/30.
//  Copyright © 2018年 huxinguang. All rights reserved.
//

#import "MediaBrowseView.h"
#import "MediaCell.h"
#import "UIView+XGAdd.h"

@interface MediaBrowseView()<UICollectionViewDelegate,UICollectionViewDataSource,UIGestureRecognizerDelegate>
@property (nonatomic, weak) UIView *fromView;
@property (nonatomic, weak) UIView *toContainerView;
@property (nonatomic, strong) UIView *blackBackground;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, assign) NSInteger fromItemIndex;
@property (nonatomic, assign) BOOL isPresented;
@property (nonatomic, assign) BOOL fromNavigationBarHidden;

@end

@implementation MediaBrowseView

- (instancetype)initWithItems:(NSArray<MediaItem *> *)items{
    self = [super init];
    if (items.count == 0) return nil;
    self.backgroundColor = [UIColor clearColor];
    self.frame = [UIScreen mainScreen].bounds;
    self.clipsToBounds = YES;
    
    _items = [items copy];
    
    [self setupSubViews];
    [self addGesture];
    
    return self;
}

- (void)setupSubViews{
    [self addSubview:self.blackBackground];
    [self addSubview:self.collectionView];
}

#pragma mark - Getter & Setter

- (UIView *)blackBackground{
    if (!_blackBackground) {
        _blackBackground = [UIView new];
        _blackBackground.frame = self.bounds;
        _blackBackground.backgroundColor = [UIColor blackColor];
        _blackBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _blackBackground;
}

-(UICollectionView *)collectionView{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        layout.itemSize = [UIScreen mainScreen].bounds.size;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = [[UICollectionView alloc]initWithFrame:self.bounds collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.pagingEnabled = YES;
        _collectionView.showsHorizontalScrollIndicator = NO;
        [_collectionView registerClass:[MediaCell class] forCellWithReuseIdentifier:NSStringFromClass([MediaCell class])];
    }
    return _collectionView;
}

- (NSInteger)currentPage{
    NSInteger page = self.collectionView.contentOffset.x / self.collectionView.width + 0.5;
    if (page >= _items.count) page = (NSInteger)_items.count - 1;
    if (page < 0) page = 0;
    return page;
}

#pragma mark - Gesture

- (void)addGesture{
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSingleTap)];
    singleTap.delegate = self;
    [self addGestureRecognizer:singleTap];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDoubleTap:)];
    doubleTap.delegate = self;
    doubleTap.numberOfTapsRequired = 2;
    [singleTap requireGestureRecognizerToFail:doubleTap];
    [self addGestureRecognizer:doubleTap];
    
}

- (void)onSingleTap{
    if ([self currentCell].item.mediaType == MediaItemTypeVideo) {
        return;
    }
    [self dismissAnimated:YES completion:nil];
}

- (void)onDoubleTap:(UITapGestureRecognizer *)gesture{
    if (!_isPresented) return;
    MediaCell *cell = [self currentCell];
    if (cell.item.mediaType == MediaItemTypeVideo) {
        return;
    }
    if (cell.scrollView.zoomScale > 1) {
        [cell.scrollView setZoomScale:1 animated:YES];
    } else {
        CGPoint touchPoint = [gesture locationInView:cell.imageView];
        CGFloat newZoomScale = cell.scrollView.maximumZoomScale;
        CGFloat xsize = self.width / newZoomScale;
        CGFloat ysize = self.height / newZoomScale;
        [cell.scrollView zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];
    }
}

- (void)presentFromImageView:(UIView *)fromView
                 toContainer:(UIView *)toContainer
                    animated:(BOOL)animated
                  completion:(void (^)(void))completion {
    if (!toContainer) return;
    
    _fromView = fromView;
    _fromView.alpha = 0;
    _toContainerView = toContainer;
    
    NSInteger page = -1;
    for (NSUInteger i = 0; i < self.items.count; i++) {
        if (fromView == ((MediaItem *)self.items[i]).thumbView) {
            page = (int)i;
            break;
        }
    }
    if (page == -1) page = 0;
    _fromItemIndex = page;
    
    self.size = _toContainerView.size;
    self.blackBackground.alpha = 0;
    [_toContainerView addSubview:self];

    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:page inSection:0] atScrollPosition:UICollectionViewScrollPositionRight animated:NO];
    [self.collectionView layoutIfNeeded];//关键，否则下面获取的cell是nil
    
    [UIView setAnimationsEnabled:YES];
    _fromNavigationBarHidden = [UIApplication sharedApplication].statusBarHidden;
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:animated ? UIStatusBarAnimationFade : UIStatusBarAnimationNone];
    
    MediaCell *cell = [self currentCell];
    MediaItem *item = self.items[self.currentPage];
    
    if (!item.thumbClippedToTop) {
        cell.item = item;
    }
    
    if (item.thumbClippedToTop) {
        CGRect fromFrame = [_fromView convertRect:_fromView.bounds toView:cell];
        CGRect originFrame = cell.mediaContainerView.frame;
        CGFloat scale = fromFrame.size.width / cell.mediaContainerView.width;
        
        cell.mediaContainerView.centerX = CGRectGetMidX(fromFrame);
        cell.mediaContainerView.height = fromFrame.size.height / scale;
        [cell.mediaContainerView.layer setValue:@(scale) forKeyPath:@"transform.scale"];
        cell.mediaContainerView.centerY = CGRectGetMidY(fromFrame);
        
        float oneTime = animated ? 0.25 : 0;
        [UIView animateWithDuration:oneTime delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut animations:^{
            self.blackBackground.alpha = 1;
        }completion:NULL];
        
        [UIView animateWithDuration:oneTime delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [cell.mediaContainerView.layer setValue:@1 forKeyPath:@"transform.scale"];
            cell.mediaContainerView.frame = originFrame;
        }completion:^(BOOL finished) {
            self.isPresented = YES;
            self.collectionView.userInteractionEnabled = YES;
            //如果打开的是视频，则创建播放器并播放
//            if (item.mediaType == MediaItemTypeVideo) {
//                cell.player.frame = cell.imageView.bounds;
//                cell.player.delegate = self;
//                [cell.mediaContainerView addSubview:cell.player];
//                [cell.player play];
//            }
            if (completion) completion();
        }];
        
    } else {
        CGRect fromFrame = [_fromView convertRect:_fromView.bounds toView:cell.mediaContainerView];
        
        cell.mediaContainerView.clipsToBounds = NO;
        cell.imageView.frame = fromFrame;
        cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
        
        float oneTime = animated ? 0.18 : 0;
        [UIView animateWithDuration:oneTime*2 delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut animations:^{
            self.blackBackground.alpha = 1;
        }completion:NULL];
        
        self.collectionView.userInteractionEnabled = NO;
        [UIView animateWithDuration:oneTime delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut animations:^{
            cell.imageView.frame = cell.mediaContainerView.bounds;
            [cell.imageView.layer setValue:@1.01 forKeyPath:@"transform.scale"];
        }completion:^(BOOL finished) {
            [UIView animateWithDuration:oneTime delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut animations:^{
                [cell.imageView.layer setValue:@1.0 forKeyPath:@"transform.scale"];
            }completion:^(BOOL finished) {
                cell.mediaContainerView.clipsToBounds = YES;
                self.isPresented = YES;
                self.collectionView.userInteractionEnabled = YES;
                //如果打开的是视频，则创建播放器并播放
//                if (item.mediaType == MediaItemTypeVideo) {
//                    cell.player.frame = cell.imageView.bounds;
//                    cell.player.delegate = self;
//                    [cell.mediaContainerView addSubview:cell.player];
//                    [cell.player layoutIfNeeded];
//                    [cell.player play];
//                }
                if (completion) completion();
            }];
        }];
    }
}


- (void)dismissAnimated:(BOOL)animated completion:(void (^)(void))completion {
    [UIView setAnimationsEnabled:YES];
    
    [[UIApplication sharedApplication] setStatusBarHidden:self.fromNavigationBarHidden withAnimation:animated ? UIStatusBarAnimationFade : UIStatusBarAnimationNone];
    NSInteger currentPage = self.currentPage;
    MediaCell *cell = [self currentCell];
    MediaItem *item = self.items[currentPage];
    
    UIView *fromView = nil;
    if (self.fromItemIndex == currentPage) {
        fromView = self.fromView;
    } else {
        fromView = item.thumbView;
        fromView.alpha = 0;
        self.fromView.alpha = 1.0;
    }
    
    self.isPresented = NO;
    BOOL isFromImageClipped = fromView.layer.contentsRect.size.height < 1;
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    if (isFromImageClipped) {
        CGRect frame = cell.mediaContainerView.frame;
        cell.mediaContainerView.layer.anchorPoint = CGPointMake(0.5, 0);
        cell.mediaContainerView.frame = frame;
    }
    [CATransaction commit];
    
    if (fromView == nil) {
        [UIView animateWithDuration:animated ? 0.25 : 0 delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut animations:^{
            self.alpha = 0.0;
            [self.collectionView.layer setValue:@0.95 forKeyPath:@"transform.scale"];
            self.collectionView.alpha = 0;
            self.blackBackground.alpha = 0;
        }completion:^(BOOL finished) {
            [self.collectionView.layer setValue:@1 forKeyPath:@"transform.scale"];
            [self removeFromSuperview];
            if (completion) completion();
        }];
        return;
    }
    
    if (isFromImageClipped) {
        CGPoint off = cell.scrollView.contentOffset;
        off.y = 0 - cell.scrollView.contentInset.top;
        [cell.scrollView setContentOffset:off animated:NO];
    }
    
    [UIView animateWithDuration:animated ? 0.2 : 0 delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut animations:^{
        self.blackBackground.alpha = 0.0;
        
        if (isFromImageClipped) {
            
            CGRect fromFrame = [fromView convertRect:fromView.bounds toView:cell];
            CGFloat scale = fromFrame.size.width / cell.mediaContainerView.width * cell.scrollView.zoomScale;
            CGFloat height = fromFrame.size.height / fromFrame.size.width * cell.mediaContainerView.width;
            if (isnan(height)) height = cell.mediaContainerView.height;
            
            cell.mediaContainerView.height = height;
            cell.mediaContainerView.center = CGPointMake(CGRectGetMidX(fromFrame), CGRectGetMinY(fromFrame));
            [cell.mediaContainerView.layer setValue:@(scale) forKeyPath:@"transform.scale"];
            
        } else {
            CGRect fromFrame = [fromView convertRect:fromView.bounds toView:cell.mediaContainerView];
            cell.mediaContainerView.clipsToBounds = NO;
            cell.imageView.contentMode = fromView.contentMode;
            cell.imageView.frame = fromFrame;
        }
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:animated ? 0.15 : 0 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.alpha = 0;
            fromView.alpha = 1.0;
        } completion:^(BOOL finished) {
            cell.mediaContainerView.layer.anchorPoint = CGPointMake(0.5, 0.5);
            [self removeFromSuperview];
            
            if (completion) completion();
        }];
    }];
    
    
}


- (MediaCell *)currentCell{
    return (MediaCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentPage inSection:0]];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    MediaCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([MediaCell class]) forIndexPath:indexPath];
    cell.item = self.items[indexPath.row];
    return cell;
}



/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
