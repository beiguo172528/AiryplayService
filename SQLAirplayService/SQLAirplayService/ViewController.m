//
//  ViewController.m
//  SQLAirplayService
//
//  Created by DOFAR on 2021/3/8.
//

#import "ViewController.h"
#import "Utils.h"

@interface ViewController ()
@property(nonatomic, assign) BOOL isOpen;
@property(nonatomic, strong) Utils *util;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.isOpen = false;
    // Do any additional setup after loading the view.
}

- (IBAction)onClickBtn:(UIButton*)sender {
    if((self.util == nil)){
        self.util = [[Utils alloc] init];
    }
    if(self.isOpen){
        [self.util removeRecordService];
    }
    else{
        [self.util registerServiceName:@"Dofar-tesm_1" withIP:@"192.168.120.98"];
    }
    self.isOpen = !self.isOpen;
    [sender setTitle:(self.isOpen ? @"关闭" : @"打开") forState:UIControlStateNormal];
    
}

@end
