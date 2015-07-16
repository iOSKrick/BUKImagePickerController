//
//  BUKAlbumsViewController.m
//  BUKImagePickerController
//
//  Created by Yiming Tang on 7/9/15.
//  Copyright (c) 2015 Yiming Tang. All rights reserved.
//

@import AssetsLibrary;

#import "BUKAlbumsViewController.h"
#import "BUKAssetsViewController.h"
#import "BUKAlbumTableViewCell.h"
#import "BUKAssetsManager.h"
#import "UIImage+BUKImagePickerController.h"

static NSString *const kBUKAlbumsViewControllerCellIdentifier = @"albumCell";

@interface BUKAlbumsViewController ()
@property (nonatomic, readwrite) NSArray *assetsGroups;
@end


@implementation BUKAlbumsViewController

#pragma mark - NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ALAssetsLibraryChangedNotification object:nil];
}


#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStyleDone target:self action:@selector(done:)];
    self.title = NSLocalizedString(@"Photos", nil);
    
    self.tableView.rowHeight = 90.0;
    [self.tableView registerClass:[BUKAlbumTableViewCell class] forCellReuseIdentifier:kBUKAlbumsViewControllerCellIdentifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assetsLibraryChanged:) name:ALAssetsLibraryChangedNotification object:nil];
    
    // Load assets groups
    __weak typeof(self)weakSelf = self;
    [self updateAssetsGroupsWithCompletion:^{
        [weakSelf.tableView reloadData];
    }];
}


#pragma mark - Actions

- (void)cancel:(id)sender {
    if ([self.delegate respondsToSelector:@selector(albumsViewControllerDidCancel:)]) {
        [self.delegate albumsViewControllerDidCancel:self];
    } else {
         [self dismissViewControllerAnimated:YES completion:nil];
    }
}


- (void)done:(id)sender {
    if ([self.delegate respondsToSelector:@selector(albumsViewControllerDidFinishPicking:)]) {
        [self.delegate albumsViewControllerDidFinishPicking:self];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.assetsGroups.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BUKAlbumTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kBUKAlbumsViewControllerCellIdentifier forIndexPath:indexPath];
    [self configureCell:cell forRowAtIndexPath:indexPath];
    
    return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(albumsViewController:didSelectAssetsGroup:)]) {
        [self.delegate albumsViewController:self didSelectAssetsGroup:[self assetsGroupAtIndexPath:indexPath]];
    }
}


#pragma mark - Private

- (BOOL)hasContent {
    return self.assetsGroups.count > 0;
}


- (ALAssetsGroup *)assetsGroupAtIndexPath:(NSIndexPath *)indexPath {
    return self.assetsGroups[indexPath.row];
}


- (void)configureCell:(BUKAlbumTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    ALAssetsGroup *assetsGroup = [self assetsGroupAtIndexPath:indexPath];
    NSString *groupName = [assetsGroup valueForProperty:ALAssetsGroupPropertyName];
    
    cell.titleLabel.text = [NSString stringWithFormat:@"%@ (%ld)", groupName, (long)assetsGroup.numberOfAssets];
    cell.tag = indexPath.row;
    
    NSUInteger numberOfAssets = MIN(3, [assetsGroup numberOfAssets]);
    
    if (numberOfAssets == 0) {
        cell.backImageView.hidden = NO;
        cell.middleImageView.hidden = NO;
        
        UIImage *placeholderImage = [UIImage buk_albumPlaceholderImageWithSize:CGSizeMake(68.0, 68.0)];
        cell.frontImageView.image = placeholderImage;
        cell.middleImageView.image = placeholderImage;
        cell.backImageView.image = placeholderImage;
    } else {
        NSRange range = NSMakeRange([assetsGroup numberOfAssets] - numberOfAssets, numberOfAssets);
        NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:range];
        
        cell.backImageView.hidden = YES;
        cell.middleImageView.hidden = YES;
        
        [assetsGroup enumerateAssetsAtIndexes:indexes options:kNilOptions usingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
            if (!asset || cell.tag != indexPath.row) return;
            
            UIImage *thumbnail = [UIImage imageWithCGImage:[asset thumbnail]];
            if (index == NSMaxRange(range) - 1) {
                cell.frontImageView.hidden = NO;
                cell.frontImageView.image = thumbnail;
            } else if (index == NSMaxRange(range) - 2) {
                cell.middleImageView.hidden = NO;
                cell.middleImageView.image = thumbnail;
            } else {
                cell.backImageView.hidden = NO;
                cell.backImageView.image = thumbnail;
            }
        }];
    }
}


- (void)assetsLibraryChanged:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        __weak typeof(self)weakSelf = self;
        [self updateAssetsGroupsWithCompletion:^{
            [weakSelf.tableView reloadData];
        }];
    });
}


#pragma mark - Fetching AssetsGroups

- (void)updateAssetsGroupsWithCompletion:(void (^)(void))completion {
    [self.assetsManager fetchAssetsGroupsWithCompletion:^(NSArray *assetsGroups) {
        self.assetsGroups = assetsGroups;
        if (completion) {
            completion();
        }
    }];
}

@end
