//
//  QMChatViewController.m
//  Q-municate
//
//  Created by Igor Alefirenko on 01/04/2014.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import "QMChatViewController.h"
#import "QMChatViewCell.h"
#import "QMChatDataSource.h"
#import "QMContactList.h"
#import "QMChatService.h"

static CGFloat const kCellHeightOffset = 33.0f;

@interface QMChatViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *inputMessageView;
@property (weak, nonatomic) IBOutlet UITextField *inputMessageTextField;
@property (nonatomic, strong) QMChatDataSource *dataSource;

@end

@implementation QMChatViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = self.chatName;
    self.dataSource = [[QMChatDataSource alloc] init];
    [self configureInputMessageViewShadow];
    [self addKeyboardObserver];
	[self addChatObserver];

	QBUUser *user = [QMContactList shared].me;
    user.password = [[NSUserDefaults standardUserDefaults] objectForKey:kPassword];

	[self configureNavBarButtons];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addChatObserver
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chatDidNotSendMessage:) name:kChatDidNotSendMessage object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chatDidReceiveMessage:) name:kChatDidReceiveMessage object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chatDidFailWithError:) name:kChatDidFailWithError object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chatDidSendMessage:) name:kChatDidSendMessage object:nil];
}

- (void)configureNavBarButtons
{
	BOOL isGroupChat = YES;

	if (isGroupChat) {
		UIButton *groupInfoButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[groupInfoButton setFrame:CGRectMake(0, 0, 30, 40)];

		[groupInfoButton setImage:[UIImage imageNamed:@"ic_info_top"] forState:UIControlStateNormal];
		[groupInfoButton setImage:[UIImage imageNamed:@"ic_info_top"] forState:UIControlStateHighlighted];
		[groupInfoButton addTarget:self action:@selector(groupInfoNavButtonAction) forControlEvents:UIControlEventTouchUpInside];
		UIBarButtonItem *groupInfoBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:groupInfoButton];
		self.navigationItem.rightBarButtonItems = @[groupInfoBarButtonItem];
	} else {
		UIButton *videoButton = [UIButton buttonWithType:UIButtonTypeCustom];
		UIButton *audioButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[videoButton setFrame:CGRectMake(0, 0, 30, 40)];
		[audioButton setFrame:CGRectMake(0, 0, 30, 40)];

		[videoButton setImage:[UIImage imageNamed:@"ic_camera_top"] forState:UIControlStateNormal];
		[videoButton setImage:[UIImage imageNamed:@"ic_camera_top"] forState:UIControlStateHighlighted];
		[videoButton addTarget:self action:@selector(videoCallAction) forControlEvents:UIControlEventTouchUpInside];

		[audioButton setImage:[UIImage imageNamed:@"ic_phone_top"] forState:UIControlStateNormal];
		[audioButton setImage:[UIImage imageNamed:@"ic_phone_top"] forState:UIControlStateHighlighted];
		[audioButton addTarget:self action:@selector(audioCallAction) forControlEvents:UIControlEventTouchUpInside];

		UIBarButtonItem *videoCallBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:videoButton];
		UIBarButtonItem *audioCallBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:audioButton];
		self.navigationItem.rightBarButtonItems = @[audioCallBarButtonItem, videoCallBarButtonItem];
	}
}


- (void)addKeyboardObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resizeViewWithKeyboardNotification:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resizeViewWithKeyboardNotification:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)configureInputMessageViewShadow
{
    self.inputMessageView.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    self.inputMessageView.layer.shadowOffset = CGSizeMake(0, -1.0);
    self.inputMessageView.layer.shadowOpacity = 0.5;
    self.inputMessageView.layer.shadowPath = [UIBezierPath bezierPathWithRect:[self.inputMessageView bounds]].CGPath;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)back:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataSource.chatHistory count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    QMChatViewCell *cell = (QMChatViewCell *)[tableView dequeueReusableCellWithIdentifier:kChatViewCellIdentifier];
    NSDictionary *messageDictionary = self.dataSource.chatHistory[indexPath.row];

    [cell configureCellWithMessage:messageDictionary fromUser:nil];

    return cell;
}

// height for cell:
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *message = self.dataSource.chatHistory[indexPath.row];
    if (kMessageString == nil) {
        return 0;
    }
    return [QMChatViewCell cellHeightForMessage:message] + kCellHeightOffset;
}


#pragma mark - Keyboard

- (void)resizeViewWithKeyboardNotification:(NSNotification *)notification
{
    NSDictionary * userInfo = notification.userInfo;
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardFrame;
    [[userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];
    
    BOOL isKeyboardShow = !(keyboardFrame.origin.y == [[UIScreen mainScreen] bounds].size.height);
    
    NSInteger keyboardHeight = isKeyboardShow ? - keyboardFrame.size.height +49.0f: keyboardFrame.size.height -49.0f;
    
    [UIView animateWithDuration:animationDuration delay:0.0f options:animationCurve << 16 animations:^
     {
         CGRect frame = self.view.frame;
         frame.size.height += keyboardHeight;
         self.view.frame = frame;
         
         [self.view layoutIfNeeded];
         
     } completion:nil];
}

- (IBAction)keyboardWillHide:(id)sender
{
    [sender resignFirstResponder];
}

#pragma mark - Nav Bar Buttons Actions
- (void)videoCallAction
{
	//
}

- (void)audioCallAction
{
	//
}

- (void)groupInfoNavButtonAction
{
	//
}

#pragma mark - Chat Notifications
- (void)chatDidNotSendMessage:(NSNotification *)notification
{
	//
}

- (void)chatDidReceiveMessage:(NSNotification *)notification
{

}

- (void)chatDidFailWithError:(NSNotification *)notification
{
	//
}

- (void)chatDidSendMessage:(NSNotification *)notification
{
	[self addMessageToHistory];
}

#pragma mark -
- (IBAction)sendMessageButtonClicked:(UIButton *)sender
{
	if (self.inputMessageTextField.text.length) {
		QBChatMessage *chatMessage = [QBChatMessage new];
		chatMessage.text = self.inputMessageTextField.text;
		chatMessage.senderID = [QMContactList shared].me.ID;
		chatMessage.recipientID = [self.usersRecipientsIdArray[0] unsignedIntegerValue];
		[[QMChatService shared] postMessage:chatMessage];
	}
}

- (void)addMessageToHistory
{
	//
}


@end
