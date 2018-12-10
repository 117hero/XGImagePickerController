//
//  ViewController.m
//  XGImagePickerController
//
//  Created by huxinguang on 2018/11/6.
//  Copyright © 2018年 huxinguang. All rights reserved.
//

#import "ViewController.h"
#import "XG_AssetPickerController.h"
#import "SelectedAssetCell.h"

#define kCollectionViewSectionInsetLeftRight 4
#define kItemCountAtEachRow 3
#define kMinimumInteritemSpacing 4
#define kMinimumLineSpacing 4

@interface ViewController ()<XG_AssetPickerControllerDelegate,UIAlertViewDelegate,UICollectionViewDelegate,UICollectionViewDataSource>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray<XG_AssetModel *> *assets;
@property (nonatomic, strong) XG_AssetModel *placeholderModel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
    CGFloat itemWH = (self.view.frame.size.width - (kItemCountAtEachRow-1)*kMinimumInteritemSpacing - 2*kCollectionViewSectionInsetLeftRight)/kItemCountAtEachRow;
    layout.itemSize = CGSizeMake(itemWH, itemWH);
    layout.minimumInteritemSpacing = kMinimumInteritemSpacing;
    layout.minimumLineSpacing = kMinimumLineSpacing;
    layout.sectionInset = UIEdgeInsetsMake(0, kCollectionViewSectionInsetLeftRight, 0, kCollectionViewSectionInsetLeftRight);
    self.collectionView.collectionViewLayout = layout;
}

-(NSMutableArray<XG_AssetModel *> *)assets{
    if (!_assets) {
        _assets = @[self.placeholderModel].mutableCopy;
    }
    return _assets;
}

-(XG_AssetModel *)placeholderModel{
    if (!_placeholderModel) {
        _placeholderModel = [[XG_AssetModel alloc]init];
        _placeholderModel.isPlaceholder = YES;
    }
    return _placeholderModel;
}


- (void)openAlbum{
    __weak typeof (self) weakSelf = self;
    [[XG_AssetPickerManager manager] handleAuthorizationWithCompletion:^(XG_AuthorizationStatus aStatus) {
        if (aStatus == XG_AuthorizationStatusAuthorized) {
            [weakSelf showAssetPickerController];
        }else{
            [weakSelf showAlert];
        }
    }];
}

- (void)showAssetPickerController{
    XG_AssetPickerOptions *options = [[XG_AssetPickerOptions alloc]init];
    options.maxAssetsCount = 9;
    options.videoPickable = YES;
    NSMutableArray<XG_AssetModel *> *array = [self.assets mutableCopy];
    [array removeLastObject];//去除占位model
    options.pickedAssetModels = array;
    XG_AssetPickerController *photoPickerVc = [[XG_AssetPickerController alloc] initWithOptions:options delegate:self];
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:photoPickerVc];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)showAlert{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"未开启相册权限，是否去设置中开启？" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"去设置", nil];
    [alert show];
}


- (void)onDeleteBtnClick:(UIButton *)sender{
    /*
     performBatchUpdates并不会调用代理方法collectionView: cellForItemAtIndexPath，
     如果用删除按钮的tag来标识则tag不会更新,所以此处没有用tag
     */
    SelectedAssetCell *cell = (SelectedAssetCell *)sender.superview.superview;
    NSIndexPath *indexpath = [self.collectionView indexPathForCell:cell];
    [self.collectionView performBatchUpdates:^{
        [self.collectionView deleteItemsAtIndexPaths:@[indexpath]];
        [self.assets removeObjectAtIndex:indexpath.item];
        if (self.assets.count == 8 && ![self.assets containsObject:self.placeholderModel]) {
            [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:8 inSection:0]]];
            [self.assets addObject:self.placeholderModel];
        }
    } completion:^(BOOL finished) {

    }];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        //取消
    }else{
        //去设置
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.assets.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    SelectedAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SelectedAssetCell class]) forIndexPath:indexPath];
    cell.model = self.assets[indexPath.item];
    [cell.deleteBtn addTarget:self action:@selector(onDeleteBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}


#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    XG_AssetModel *model = self.assets[indexPath.item];
    if (model.isPlaceholder) {
        [self openAlbum];
    }
}

#pragma mark - XG_AssetPickerControllerDelegate

- (void)assetPickerController:(XG_AssetPickerController *)picker didFinishPickingAssets:(NSArray<XG_AssetModel *> *)assets{
    NSMutableArray *newAssets = assets.mutableCopy;
    if (newAssets.count < 9 ) {
        [newAssets addObject:self.placeholderModel];
    }
    self.assets = newAssets;
    [self.collectionView reloadData];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
