class Notifier < ActionMailer::Base
  def gma(sender, recipients, subject, doc)
    recipients recipients
    from       sender
    subject    subject
    body       doc
    content_type "text/html"
  end
end
