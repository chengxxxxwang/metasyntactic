package org.metasyntactic;

import android.app.ListActivity;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import android.view.*;
import android.widget.*;
import org.metasyntactic.data.Review;
import org.metasyntactic.utilities.MovieViewUtilities;

import java.util.List;

public class AllReviewsActivity extends ListActivity {
  private List<Review> reviews;

  @Override protected void onCreate(final Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    NowPlayingControllerWrapper.addActivity(this);
    this.reviews = getIntent().getParcelableArrayListExtra("reviews");
    setListAdapter(new ReviewsAdapter(this));
  }

  @Override protected void onListItemClick(final ListView l, final View v, final int position, final long id) {
    Log.i("test", "on list item click");
    String review_url = null;
    review_url = reviews.get(position).getLink();
    if (review_url != null) {
      final Intent intent = new Intent("android.intent.action.VIEW", Uri.parse(review_url));
      startActivity(intent);
    } else {
      Toast.makeText(AllReviewsActivity.this, "This review article is not available.", Toast.LENGTH_SHORT).show();
    }
    super.onListItemClick(l, v, position, id);
  }

  protected void onDestroy() {
    NowPlayingControllerWrapper.removeActivity(this);
    super.onDestroy();
  }

  private class ReviewsAdapter extends BaseAdapter {
    private final LayoutInflater inflater;

    public ReviewsAdapter(final Context context) {
      // Cache the LayoutInflate to avoid asking for a new one each time.
      this.inflater = LayoutInflater.from(context);
    }

    public Object getItem(final int i) {
      return i;
    }

    public long getItemId(final int i) {
      return i;
    }

    public View getView(final int position, View convertView, final ViewGroup viewGroup) {
      final MovieViewHolder holder;
      convertView = this.inflater.inflate(R.layout.reviewview, null);
      holder = new MovieViewHolder((ImageView) convertView.findViewById(R.id.score),
                                   (TextView) convertView.findViewById(R.id.author),
                                   (TextView) convertView.findViewById(R.id.source),
                                   (TextView) convertView.findViewById(R.id.desc));
      convertView.setTag(holder);
      final Review review = AllReviewsActivity.this.reviews.get(position);
      holder.author.setText(review.getAuthor());
      holder.source.setText(review.getSource());
      holder.description.setText(review.getText());
      // todo holder score image set.
      return convertView;
    }

    private class MovieViewHolder {
      private final ImageView score;
      private final TextView author;
      private final TextView source;
      private final TextView description;

      private MovieViewHolder(final ImageView score, final TextView author, final TextView source, final TextView description) {
        this.score = score;
        this.author = author;
        this.source = source;
        this.description = description;
      }
    }

    public int getCount() {
      return AllReviewsActivity.this.reviews.size();
    }
  }

  @Override public boolean onCreateOptionsMenu(final Menu menu) {
    menu.add(0, MovieViewUtilities.MENU_MOVIES, 0, R.string.menu_movies).setIcon(R.drawable.movies).setIntent(
        new Intent(this, NowPlayingActivity.class)).setAlphabeticShortcut('m');
    menu.add(0, MovieViewUtilities.MENU_THEATER, 0, R.string.menu_theater).setIcon(R.drawable.theatres);
    menu.add(0, MovieViewUtilities.MENU_UPCOMING, 0, R.string.menu_upcoming).setIcon(R.drawable.upcoming);
    menu.add(0, MovieViewUtilities.MENU_SETTINGS, 0, R.string.menu_settings).setIcon(
        android.R.drawable.ic_menu_preferences).setIntent(
        new Intent(this, SettingsActivity.class)).setAlphabeticShortcut('s');
    return super.onCreateOptionsMenu(menu);
  }

  @Override public boolean onOptionsItemSelected(final MenuItem item) {
    if (item.getItemId() == MovieViewUtilities.MENU_THEATER) {
      final Intent intent = new Intent();
      intent.setClass(AllReviewsActivity.this, AllTheatersActivity.class);
      startActivity(intent);
      return true;
    }
    return false;
  }
}
