module ApplicationHelper
  def ec2_metadata_fragment_path(path = '')
    File.join('/ec2/metadata/', path)
  end
end
