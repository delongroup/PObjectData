Pod::Spec.new do |spec|
  spec.name         = 'PObjectData'
  spec.version      = '1.0'
  spec.license      =  { :type => 'BSD' }
  spec.homepage     = 'PObjectData'
  spec.authors      = { 'delon chen' => 'delonchen@126.com'}
  spec.summary      = 'Plain Object FMDB Extension.'
  spec.source       = { :git => '~/Work2014/PObjectData' }
  spec.source_files = 'PObjectData/'
  spec.requires_arc = false
  spec.ios.deployment_target = '6.0'
end
