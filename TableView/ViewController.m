//
//  ViewController.m
//  TableView
//
//  Created by Alvin Kuang on 11/23/16.
//  Copyright © 2016 Alvin Kuang. All rights reserved.
//

#import "ViewController.h"
#import "TopStory.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <AFNetworking.h>


@interface ViewController () <UITableViewDelegate, UITableViewDataSource, SFSafariViewControllerDelegate>

@property (nonatomic, strong) UITableView *resultsTableView;
@property (nonatomic, strong) NSMutableArray<TopStory *> *topStoriesArray;

@end

static NSString * const urlString = @"https://api.nytimes.com/svc/topstories/v1/home.json?api-key=8932450deee14cd69932425535f9df69";
static int maxNumItemsPerSection =10;

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setHidden:NO];

    self.topStoriesArray = [[NSMutableArray<TopStory *> alloc] init];
    [self fetchData];
    
    self.resultsTableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    
    [self.resultsTableView setDelegate:self];
    [self.resultsTableView setDataSource:self];

    // *** Register custom UITableViewCell class that contains the custom cell view
    [self.resultsTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell_reuse"];
    self.resultsTableView.backgroundColor = [UIColor lightGrayColor];
    self.resultsTableView.rowHeight = 90;
    [self.view addSubview:self.resultsTableView];
    [self.resultsTableView setScrollsToTop:YES];

}

-(void)fetchData {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:urlString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {        
        NSArray *dataArray = [responseObject objectForKey:@"results"];
        
        for (int i = 0; i < dataArray.count; i++) {
            TopStory *topStoryObj = [[TopStory alloc] init];
            NSDictionary *dataObj = dataArray[i];
            
            
            
            NSString *articleTitle = [dataObj objectForKey:@"title"];
            NSLog(@"%d, %@", i, articleTitle);
            if (articleTitle.length > 0) {
                [topStoryObj setTopStoryTitle:articleTitle];
            }
            
            
            
            NSString *articleURL = [dataObj objectForKey:@"url"];
            if (articleURL.length > 0) {
                [topStoryObj setTopStoryURL:articleURL];
            }
            
            if ([[dataObj objectForKey:@"multimedia"] isKindOfClass:[NSArray class]]) {
                NSArray *topStoryMediaArray = [dataObj objectForKey:@"multimedia"];
                NSString *articleImageURL = [[topStoryMediaArray firstObject] objectForKey:@"url"];
                
                if (articleImageURL.length > 0) {
                    [topStoryObj setTopStoryImageURL:articleImageURL];
                }
                
            }
            
            [self.topStoriesArray addObject:topStoryObj];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.resultsTableView reloadData];
        });

        
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];

}

#pragma - SFSafariViewController delegate

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    [self dismissViewControllerAnimated:true completion:nil];
}

#pragma - UITableView DataSource methods

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.topStoriesArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // *** Once the custom cell layout class is registered, you can access the properties to set them to the corresponding data here
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell_reuse"];
    cell.backgroundColor = [UIColor grayColor];
    if (self.topStoriesArray.count > 0) {
        [cell.imageView setClipsToBounds:YES];
        cell.imageView.contentMode = UIViewContentModeCenter;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.numberOfLines = 2;
        cell.textLabel.text = self.topStoriesArray[indexPath.row].topStoryTitle;
        if (self.topStoriesArray[indexPath.row].topStoryImageURL != nil) {
            [cell.imageView sd_setImageWithURL:[NSURL URLWithString:self.topStoriesArray[indexPath.row].topStoryImageURL] placeholderImage:[UIImage imageNamed:@"loading-icon.jpg"]];
        } else {
            [cell.imageView setImage:NULL];
        }
    }
    return cell;
}

#pragma - UITableView Delegate methods

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SFSafariViewController *svc = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:self.topStoriesArray[indexPath.row].topStoryURL]];
    svc.delegate = self;
    [self presentViewController:svc animated:YES completion:nil];
    
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSUInteger offsetY = scrollView.contentOffset.y;
    NSUInteger contentHeight = scrollView.contentSize.height;
    
    if (offsetY > contentHeight - scrollView.frame.size.height) {
        [self.topStoriesArray addObjectsFromArray:self.topStoriesArray];
        [self.resultsTableView reloadData];
    }
}

@end
