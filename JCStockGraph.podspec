#
# Be sure to run `pod lib lint NAME.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = "JCStockGraph"
  s.version          = "0.1.0"
  s.summary          = "A simple graph view controller which displays a stock's historical price data from the Yahoo finance API."
  s.homepage         = "http://github.com/jconst/JCStockGraph"
  s.screenshots      = "https://github.com/jconst/JCStockGraph/raw/master/ss1.png", "https://github.com/jconst/JCStockGraph/raw/master/ss2.png"
  s.license          = 'MIT'
  s.author           = { "Joseph Constantakis" => "jcon5294@gmail.com" }
  s.source           = { :git => "http://github.com/jconst/JCStockGraph.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.ios.deployment_target = '7.0'
  s.requires_arc = true

  s.source_files = 'Classes'

  s.public_header_files = 'Classes/*.h'
  s.dependency 'CorePlot', '~> 1.5'
  s.dependency 'AFNetworking', '~> 2.0'
  s.dependency 'MBProgressHUD', '~> 0.8'
  s.dependency 'MTDates', '~> 0.12'
  s.dependency 'FontasticIcons', '~> 0.5'

end
