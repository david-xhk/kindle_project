$(function() {
  var categories = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.whitespace,
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    prefetch: "/categories"
  })

  $(".bootstrap-tagsinput input").typeahead(null, {
    name: "categories",
    limit: 20,
    source: categories
  })
  
  $("#search-form").validate({
    rules: {
      "title": {
        required: function() {
          title = $("#search-title").val()
          filter_by = $("#search-filter-by").tagsinput("items")
          sort_by = $("#search-sort-by").val()
          order_by = $("#search-order-by").val()
          title_not_entered = !title.trim()
          filter_by_not_entered = filter_by.length === 0
          sort_by_selected = sort_by === "price" || sort_by === "rating"
          order_by_selected = order_by === "ascending" || order_by === "descending"
          return title_not_entered && filter_by_not_entered && !sort_by_selected && !order_by_selected
        },
      },
      "sort_by": {
        required: function() {
          sort_by = $("#search-sort-by").val()
          order_by = $("#search-order-by").val()
          sort_by_selected = sort_by === "price" || sort_by === "rating"
          order_by_selected = order_by === "ascending" || order_by === "descending"
          return !sort_by_selected && order_by_selected
        },
      },
      "order_by": {
        required: function() {
          sort_by = $("#search-sort-by").val()
          order_by = $("#search-order-by").val()
          sort_by_selected = sort_by === "price" || sort_by === "rating"
          order_by_selected = order_by === "ascending" || order_by === "descending"
          return sort_by_selected && !order_by_selected
        },
      }
    },
    messages: {
      "title": {
        required: "Please specify a search query."
      },
      "sort_by": {
        required: "Please choose what you wish to sort by."
      },
      "order_by": {
        required: "Please choose the order that you wish to sort by."
      }
    },
    errorClass: "is-invalid",
    errorElement: "small",
    focusCleanup: true,
    errorContainer: "#messageBox1, #messageBox2",
    errorLabelContainer: "#messageBox1 ul",
    errorPlacement: function(error, element) {
      $("#search-form button").before(error)
    },
    wrapper: "li",
    submitHandler: function(form) {
      $.post("/search/book", $(form).serialize())
        .done(function(data) {
          $("#search-results").remove()
          $(form).after(data)
        })
      return false
    }
  })
})
