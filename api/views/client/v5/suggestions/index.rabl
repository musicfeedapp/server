node(:artists) {
  partial('v5/suggestions/user', object: @artists, locals: { timelines: @timelines, publishers: @publishers, activities: @activities })
}

node(:trending_artists) {
  partial('v5/suggestions/user', object: @trending_artists, locals: { timelines: @trending_artists_timelines, publishers: @trending_artists_publishers, activities: @trending_artists_activities })
}

node(:trending_tracks) {
  partial('v5/suggestions/timelines', object: @trending_tracks_timelines, locals: { publishers: @trending_tracks_publishers, activities: @trending_tracks_activities })
}
