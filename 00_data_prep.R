
## data available
## @ http://www2.informatik.uni-freiburg.de/~cziegler/BX/BX-CSV-Dump.zip

library(tidyverse)

load_csv <- function(strng_path) {
  csv_df <- read_delim(strng_path, 
                       delim = ";", escape_double = FALSE, trim_ws = TRUE) %>% 
    janitor::clean_names()
  return(csv_df)
}

ratings <- load_csv("csv_df/BX-Book-Ratings.csv") 
books <- load_csv("csv_df/BX-Books.csv")
users <- load_csv("csv_df/BX-Users.csv")

books$isbn <- paste0("isbn_",books$isbn)
users$user_id <- paste0("user_",users$user_id)
ratings$isbn <- paste0("isbn_",ratings$isbn)
ratings$user_id <- paste0("user_",ratings$user_id)

n_distinct(ratings$isbn) # 204678
n_distinct(ratings$user_id) # 44778

table(ratings$book_rating)

book_rated_n_times <- ratings %>% group_by(isbn) %>% 
  summarise(n_reviews = n()) %>% arrange(desc(n_reviews))
head(book_rated_n_times, 20)
tail(book_rated_n_times, 20)

users_rated_n_times <- ratings %>% group_by(user_id) %>% 
  summarise(n_reviews = n()) %>% arrange(desc(n_reviews))
head(users_rated_n_times, 20)
tail(users_rated_n_times, 20)

rb <- book_rated_n_times %>% ggplot(aes(x  = n_reviews)) + 
  geom_histogram(bins = 500) + 
  labs(x = "# of Reviews",
       subtitle = "... book review numbers") + 
  theme_bw() 
urn <- users_rated_n_times %>% ggplot(aes(x  = n_reviews)) + 
  geom_histogram(bins = 500) + 
  labs(x = "# of Reviews",
       subtitle = "... user review numbers") + 
  theme_bw()

library(patchwork)
(rb + urn) + plot_annotation(title = "Distribution of ...")

## limit to books rated > 10 times
book_rated_n_times <- book_rated_n_times %>% filter(n_reviews >= 10)
## limit to users rated > 20 books
users_rated_n_times <- users_rated_n_times %>% filter(n_reviews >= 20)

## apply the filter
### rating with books rated > 10 times & users rated > 20 times
ratings <- ratings %>% filter(
  isbn %in% book_rated_n_times$isbn & 
    user_id %in% users_rated_n_times$user_id)

table(ratings$book_rating)

## remove books with 0 ratings
ratings <- ratings %>% filter(book_rating > 0)

n_distinct(ratings$isbn) # 6340
n_distinct(ratings$user_id) # 2774

## take a random sample
set.seed(2022)
ratings <- ratings %>% sample_frac(.5, replace = FALSE)
n_distinct(ratings$isbn) # 5554
n_distinct(ratings$user_id) # 2531
books <- books %>% filter(isbn %in% ratings$isbn)
users <- users %>% filter(user_id %in% ratings$user_id)

us_rat_mat <- ratings %>% 
  pivot_wider(names_from = isbn, values_from = book_rating) %>%
  column_to_rownames(var = "user_id")

us_rat_mat <- data.matrix(us_rat_mat)

library(recommenderlab)
BookRatingsMatrix <- as(us_rat_mat, "realRatingMatrix")

gdata::keep(BookRatingsMatrix, books, users, ratings, sure = TRUE)

pacman::p_loaded()
pacman::p_unload(all)

save.image(file = "data/BookRatings.RData")
