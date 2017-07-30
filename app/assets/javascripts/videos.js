import $ from 'jquery';

$(document).ready(() => {
  if (!($('#new_video').length > 0)) {
    return;
  }

  // Ensure segments are cleared.
  $('#video_key').val('');

  // Hide form until link is confirmed.
  $('#new_video').hide();
  $('#tournament-select').hide();
  $('.video-aff-debaters').hide();
  $('.video-neg-debaters').hide();

  // Bind autocompletes.
  const createSearchChoice = function(term, data) {
    if (
      $(data).filter(function() {
        return this.text.localeCompare(term) === 0;
      }).length === 0
    ) {
      return {
        id: term,
        text: term,
      };
    }
  };

  $('.school-select').select2({
    ajax: {
      url: '/schools/autocomplete',
      delay: 250,
      data(term) {
        return { q: term };
      },
      results(data, page) {
        return { results: data };
      },
      cache: true,
    },
    createSearchChoice,
    minimumInputLength: 1,
  });

  $('.aff-debater-select').select2({
    ajax: {
      url: '/debaters/autocomplete',
      delay: 250,
      data(term) {
        const school = $('#video_aff_school').val();
        if (isNaN(school)) {
          return { q: false };
        } else {
          return { school, q: term };
        }
      },
      results(data, page) {
        return { results: data };
      },
      cache: true,
    },
    createSearchChoice,
    minimumInputLength: 1,
  });

  $('.neg-debater-select').select2({
    ajax: {
      url: '/debaters/autocomplete',
      delay: 250,
      data(term) {
        const school = $('#video_neg_school').val();
        if (isNaN(school)) {
          return { q: false };
        } else {
          return { school, q: term };
        }
      },
      results(data, page) {
        return { results: data };
      },
      cache: true,
    },
    createSearchChoice,
    minimumInputLength: 1,
  });

  $('.tag-select').select2({
    ajax: {
      url: '/tags/autocomplete',
      delay: 250,
      data(term) {
        return { q: term };
      },
      results(data, page) {
        return { results: data };
      },
      cache: true,
    },
    createSearchChoice,
    minimumInputLength: 1,
    multiple: true,
  });

  $('.tournament-select').select2({
    ajax: {
      url: '/tournaments/autocomplete',
      delay: 250,
      data(term) {
        const year = $('#video_year').val();
        if (isNaN(year)) {
          return { q: false };
        } else {
          return { year, q: term };
        }
      },
      results(data, page) {
        return { results: data };
      },
      cache: true,
    },
    createSearchChoice,
    minimumInputLength: 1,
    multiple: true,
  });

  // Continue when go button clicked
  $('#video-link-go').on('click', (event) => {
    event.preventDefault();

    const link = $('#video_link_link').val();
    return $.getJSON(`/videos/info/?link=${link}`, (info) => {
      if (info.invalid) {
        return alert('Video link invalid; double-check it and try again.');
      } else if (info.exists) {
        return alert('Video has already been submitted!');
      } else {
        // Add key to the list.
        const keys = $('#video_key').val().split(',');
        if (keys.indexOf(info.key) !== -1) {
          alert('That segment has already been added!');
          return;
        } else {
          keys.push(info.key);
        }
        $('#video_key').val(keys.join(','));
        $('#video_provider').val(info.provider);
        $('#video_thumbnail').val(info.thumbnail);

        // Add the video preview.
        $('.end').removeClass('end');
        const new_html = `\
<div class="large-4 columns end">
  <strong>${info.title}</strong><br />
  <img src="${info.thumbnail}" />
</div>\
`;
        $('#video-preview').append(new_html);

        if (info.provider === 'youtube') {
          // Alter button text.
          $('#video-link-go').val('Add Segment');

          // Clear the input.
          $('#video_link_link').val('');

          $('#vimeo-text').hide();
        } else {
          // Else hide
          $('.video_link').hide();
          $('#youtube-text').hide();
        }

        // Show the metadata.
        if (!$('#new_video').is(':visible')) {
          return $('#new_video').show();
        }
      }
    });
  });

  // Show tournament dropdown when year entered.
  $('#video_year').on('keydown', () => $('#tournament-select').show());

  // Show debater dropdowns when schools selected.
  $('#video_aff_school').on('change', () => $('.video-aff-debaters').show());

  $('#video_neg_school').on('change', () => $('.video-neg-debaters').show());

  // Hide debater two if it's an LD round
  $('#video_debate_type').on('change', () => {
    if ($('#video_debate_type').val() === 'ld') {
      $('.video_aff_debater_two').hide();
      return $('.video_neg_debater_two').hide();
    } else {
      $('.video_aff_debater_two').show();
      return $('.video_neg_debater_two').show();
    }
  });

  // Validate
  return $('#new_video').on('submit', (event) => {
    if (
      $('#video_aff_debater_one').val() === '' ||
      $('#video_neg_debater_one').val() === '' ||
      $('#video_aff_school').val() === '' ||
      $('#video_neg_school').val() === '' ||
      $('#video_year').val() === '' ||
      $('#video_tournament').val() === '' ||
      $('#video_debate_level').val() === '' ||
      $('#video_debate_type').val() === ''
    ) {
      alert('Please complete all required fields.');
      return event.preventDefault();
    }
  });
});
