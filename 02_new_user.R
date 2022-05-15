
library(recommenderlab)
library(tidyverse)

load("data/BookRatings.RData")

# get new user input ------------------------------------------------------

new_user_input_df <- tibble(user_id = rep("user_9999", 6),
                            isbn = c("isbn_0385504209",
                                     "isbn_0679781587", "isbn_059035342X",
                                     "isbn_0439136350", "isbn_043935806X", 
                                     "isbn_0060938455"
                            ),
                            book_rating = c(10,4,5,8,6,12))

# add new user input into the existing ratings
updated_ratings_df <- bind_rows(ratings, new_user_df)

# convert long to wide
us_rat_mat <- updated_ratings_df %>% 
  pivot_wider(names_from = isbn, values_from = book_rating) %>%
  column_to_rownames(var = "user_id")

# prep rating matrix
# convert df into matrix
us_rat_mat <- data.matrix(us_rat_mat)

# define as realRatingsMatrix for recommender
BookRatingsMatrix <- as(us_rat_mat, "realRatingMatrix")


# cross-validate ----------------------------------------------------------

set.seed(9999)
eval_books <- evaluationScheme(data = BookRatingsMatrix, 
                               method = "cross-validation", 
                               k = 10,
                               given = 1, 
                               goodRating = 7)

train_books <- getData(eval_books, "train")
known_books <- getData(eval_books, "known")
unknown_books <- getData(eval_books, "unknown")

# run model ---------------------------------------------------------------

ibcf <- train_books %>% Recommender(method = "IBCF",
                                    parameter = list(k =  10,
                                                     method	= "Cosine",
                                                     normalize = NULL,
                                                     normalize_sim_matrix = FALSE,
                                                     alpha = 0.5,
                                                     na_as_zero = FALSE,
                                                     verbose = TRUE))

# get recommendation output -----------------------------------------------

recos_ibcf <- ibcf %>% predict(unknown_books, n = 5)
as(recos_ibcf, "list")$user_9999 %>% head(5)

