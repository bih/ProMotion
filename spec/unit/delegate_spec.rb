describe "PM::Delegate" do

  before { @subject = TestDelegate.new }

  it 'should call on_load on launch' do
    @subject.mock!(:on_load) do |app, options|
      options[:jamon].should.be.true
      app.should.be.kind_of(UIApplication)
    end

    @subject.application(UIApplication.sharedApplication, didFinishLaunchingWithOptions:{jamon: true})
  end

  it "should handle push notifications" do

    @subject.mock!(:on_push_notification) do |notification, was_launched|
      notification.should.be.kind_of(PM::PushNotification)
      notification.alert.should == "Eating Bacon"
      notification.badge.should == 42
      notification.sound.should == "jamon"
      @subject.aps_notification.should == notification
    end

    launch_options = { UIApplicationLaunchOptionsRemoteNotificationKey => PM::PushNotification.fake_notification(alert: "Eating Bacon", badge: 42, sound: "jamon").notification }
    @subject.application(UIApplication.sharedApplication, willFinishLaunchingWithOptions: nil)
    @subject.application(UIApplication.sharedApplication, didFinishLaunchingWithOptions:launch_options )

  end

  it "should return false for was_launched if the app is currently active on screen" do
    @subject.mock!(:on_push_notification) do |notification, was_launched|
      was_launched.should.be.false
    end

    UIApplication.sharedApplication.stub!(:applicationState, return: UIApplicationStateActive)
    remote_notification = PM::PushNotification.fake_notification.notification
    @subject.application(UIApplication.sharedApplication, didReceiveRemoteNotification: remote_notification)
  end

  it "should return true for was_launched if app was launched from background" do
    @subject.mock!(:on_push_notification) do |notification, was_launched|
      was_launched.should.be.true
    end

    UIApplication.sharedApplication.stub!(:applicationState, return: UIApplicationStateBackground)
    remote_notification = PM::PushNotification.fake_notification.notification
    @subject.application(UIApplication.sharedApplication, didReceiveRemoteNotification: remote_notification)
  end

  it "should return true for was_launched if the app wasn't running" do
    @subject.mock!(:on_push_notification) do |notification, was_launched|
      was_launched.should.be.true
    end

    launch_options = { UIApplicationLaunchOptionsRemoteNotificationKey => PM::PushNotification.fake_notification.notification }
    @subject.application(UIApplication.sharedApplication, didFinishLaunchingWithOptions:launch_options )
  end

  it "should set home_screen when opening a new screen" do
    @subject.application(UIApplication.sharedApplication, willFinishLaunchingWithOptions: nil)
    @subject.application(UIApplication.sharedApplication, didFinishLaunchingWithOptions: nil)
    screen = @subject.open BasicScreen.new(nav_bar: true)
    @subject.home_screen.should.be.kind_of BasicScreen
    @subject.window.rootViewController.should.be.kind_of UINavigationController
    screen.should.be.kind_of BasicScreen
  end

  it "should call will_load on launch" do
    @subject.called_will_load.should == nil
    @subject.application(UIApplication.sharedApplication, willFinishLaunchingWithOptions: nil)
    @subject.called_will_load.should == true
  end

  it "should call will_deactivate when quitting" do
    @subject.application(UIApplication.sharedApplication, willFinishLaunchingWithOptions: nil)
    @subject.application(UIApplication.sharedApplication, didFinishLaunchingWithOptions: nil)
    @subject.called_will_deactivate.should == nil
    @subject.applicationWillResignActive(UIApplication.sharedApplication)
    @subject.called_will_deactivate.should == true
  end

  it "should call on_activate when resuming from an inactive state" do
    @subject.application(UIApplication.sharedApplication, willFinishLaunchingWithOptions: nil)
    @subject.application(UIApplication.sharedApplication, didFinishLaunchingWithOptions: nil)
    @subject.applicationWillResignActive(UIApplication.sharedApplication)
    @subject.called_on_activate.should == nil
    @subject.applicationDidBecomeActive(UIApplication.sharedApplication)
    @subject.called_on_activate.should == true
  end

  it "should call on_enter_background when hitting the home button" do
    @subject.application(UIApplication.sharedApplication, willFinishLaunchingWithOptions: nil)
    @subject.application(UIApplication.sharedApplication, didFinishLaunchingWithOptions: nil)
    @subject.called_on_enter_background.should == nil
    @subject.applicationDidEnterBackground(UIApplication.sharedApplication)
    @subject.called_on_enter_background.should == true
  end

  it "should call will_enter_foreground when hitting the home button" do
    @subject.application(UIApplication.sharedApplication, willFinishLaunchingWithOptions: nil)
    @subject.application(UIApplication.sharedApplication, didFinishLaunchingWithOptions: nil)
    @subject.applicationDidEnterBackground(UIApplication.sharedApplication)
    @subject.called_will_enter_foreground.should == nil
    @subject.applicationWillEnterForeground(UIApplication.sharedApplication)
    @subject.called_will_enter_foreground.should == true
  end

  it "should call on_unload when the device is about to kill the app" do
    @subject.application(UIApplication.sharedApplication, willFinishLaunchingWithOptions: nil)
    @subject.application(UIApplication.sharedApplication, didFinishLaunchingWithOptions: nil)
    @subject.called_on_unload.should == nil
    @subject.applicationWillTerminate(UIApplication.sharedApplication)
    @subject.called_on_unload.should == true
  end

end
