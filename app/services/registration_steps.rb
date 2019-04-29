require 'aggregator'

RegistrationSteps = [
  ->(user, options) {
    return unless options[:new_user]
    maker = Facebook::Proposals::Maker.new(user, options)
    maker.find!
  },
  ->(user, options) {
    return unless options[:new_user]
    Facebook::Feed::UserWorker.perform_async(user.id, recent: false)
  },
  ->(user, options) {
    return unless options[:new_user]
    UserMailer.welcome(user.id).deliver
    # lets make sure that we have time of sent message to the user for the
    # further changes.
    user.update_column(:welcome_notified_at, DateTime.now)
  },
  ->(user, options) {
    # place here mixpanel trackers.
  },
  ->(user, options) {
    return unless options[:new_user]
    ImportPlaylistsWorker.perform_async(user.id)
  },
  ->(user, options) {
    return unless options[:new_user]
    FeedWorker::NodeWorker.perform_async(user.id)
  },
]
