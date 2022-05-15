
library(recommenderlab)
library(tidyverse)

load("data/BookRatings.RData")

# min(rowCounts(BookRatingsMatrix)) # 1
# max(rowCounts(BookRatingsMatrix)) # 101

set.seed(202205)
eval_books <- evaluationScheme(data = BookRatingsMatrix, 
                                method = "cross-validation", 
                                k = 10,
                                given = 1, 
                                goodRating = 7)

eval_books
# valuation scheme with 1 items given
# Method: ‘cross-validation’ with 10 run(s).
# Good ratings: >=7.000000
# Data set: 2531 x 5554 rating matrix of class ‘realRatingMatrix’ with 18520 ratings.

train_books <- getData(eval_books, "train")
known_books <- getData(eval_books, "known")
unknown_books <- getData(eval_books, "unknown")


# Randomly chosen items ---------------------------------------------------

random <- train_books %>% Recommender(method = "RANDOM")
random_eval <- random %>% predict(known_books, type = "ratings") %>% 
  calcPredictionAccuracy(unknown_books)
print(random_eval)


# Popular items -----------------------------------------------------------

pop <- train_books %>% Recommender(method = "POPULAR")
pop_eval <- pop %>% predict(known_books, type = "ratings") %>% 
  calcPredictionAccuracy(unknown_books)
print(pop_eval)


# Singular Value Decomposition based collaborative filtering --------------

svd <- train_books %>% Recommender(method = "SVD",
                                   parameter = list(k = 10,
                                                    maxiter	= 200,
                                                    normalize = NULL,
                                                    verbose	= TRUE))
svd_eval <- svd %>% predict(known_books, type = "ratings") %>% 
  calcPredictionAccuracy(unknown_books)
print(svd_eval)


# Funk SVD ----------------------------------------------------------------

svdf <- train_books %>% Recommender(method = "SVDF",
                                    parameter = list(k = 10,
                                                     maxiter	= 200,
                                                     normalize = NULL,
                                                     verbose	= TRUE))
svdf_eval <- svdf %>% predict(known_books, type = "ratings") %>% 
  calcPredictionAccuracy(unknown_books)
print(svdf_eval)


# Item-based collaborative filtering --------------------------------------

ibcf <- train_books %>% Recommender(method = "IBCF",
                                    parameter = list(k =  10,
                                                     method	= "Cosine",
                                                     normalize = NULL,
                                                     normalize_sim_matrix = FALSE,
                                                     alpha = 0.5,
                                                     na_as_zero = FALSE,
                                                     verbose = TRUE))
ibcf_eval <- ibcf %>% predict(known_books, type = "ratings") %>% 
  calcPredictionAccuracy(unknown_books)
print(ibcf_eval)


# User-based collaborative filtering --------------------------------------

# ubcf <- train_books %>% Recommender(method = "UBCF", param = list(method = "Cosine", normalize = "Center"))
# ubcf_eval <- ubcf %>% predict(known_books, type = "ratings") %>%
#   calcPredictionAccuracy(unknown_books)
# print(ubcf_eval)


# Alternating least squares -----------------------------------------------

# als <- train_books %>% Recommender(method = "ALS")
# als_eval <- als %>% predict(known_books, type = "ratings") %>% 
#   calcPredictionAccuracy(unknown_books)
# print(ibcf_eval)



# matrix factorization ----------------------------------------------------

libmf <- train_books %>% Recommender(method = "LIBMF")
libmf_eval <- libmf %>% predict(known_books, type = "ratings") %>%
  calcPredictionAccuracy(unknown_books)
print(ibcf_eval)

rbind(random_eval, pop_eval,
      svd_eval, svdf_eval,
      ibcf_eval, libmf_eval) %>% 
  as.data.frame() %>% 
  tibble::rownames_to_column(var = "method") %>% 
  mutate(across(RMSE:MAE, round, 2),
         method = recode(method, 
                         random_eval = "Random Evaluation",
                         pop_eval = "Popular Evaluation",
                         svd_eval = "Singular Value Decomposition",
                         svdf_eval = "Funk Singular Value Decomposition",
                         ibcf_eval = "Item-Based Collaborative Filtering",
                         libmf_eval = "Matrix factorization")) %>%
  ggplot(aes(x = method, y = RMSE)) +
  geom_col() +
  labs(x =  "Method", y = "RMSE",
       title = "Model Evaluation Metrics",
       subtitle = "Recommender Performance") + 
  theme_minimal() + theme(axis.text.x = element_text(angle = 20))
  

recos_pop <- pop %>% predict(known_books, n = 5)
as(recos_pop, "list") %>% head(4)
recos_ran <- random %>% predict(known_books, n = 5)
as(recos_ran, "list") %>% head(4)
recos_svdf <- svdf %>% predict(known_books, n = 5)
as(recos_svdf, "list") %>% head(4)
recos_ibcf <- ibcf %>% predict(known_books, n = 5)
as(recos_ibcf, "list") %>% head(4)
