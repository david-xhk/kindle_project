from pyspark.sql import SparkSession
from pyspark.ml.feature import RegexTokenizer
from pyspark.sql.functions import udf, size, avg
from pyspark.sql.types import StructType, StructField, ArrayType, StringType, IntegerType, FloatType
# from nltk import word_tokenize

if __name__ == "__main__":
    spark = SparkSession.builder.appName("Calculate Pearson correlation between average review length and price").getOrCreate()

    reviews = spark.read.csv(
        path   = "hdfs:/input/review_texts.csv",
        header = False,
        escape = "\"",
        schema = StructType([StructField("reviewId", IntegerType(), True),
                             StructField("asin", StringType(), True),
                             StructField("reviewText", StringType(), True)]))
    reviews = reviews.drop("reviewId")
    reviews = reviews.repartition(20)

    prices = spark.read.csv(
        path   = "hdfs:/input/prices.csv",
        header = False,
        schema = StructType([StructField("asin", StringType(), True),
                             StructField("price", FloatType(), True)]))

    reviews = reviews.join(prices, ["asin"], how="leftsemi")

    # # Use nltk.word_tokenizer to tokenize words
    # @udf(ArrayType(StringType()))
    # def tokenize(string):
    #     return word_tokenize(string)

    # reviews = reviews.withColumn("words", tokenize("reviewText"))

    reviews = RegexTokenizer(inputCol="reviewText", outputCol="words", pattern="\\W").transform(reviews)
    reviews = reviews.drop("reviewText")

    reviews = reviews.withColumn("num_words", size("words"))
    reviews = reviews.drop("words")

    reviews = reviews.groupBy("asin").agg(avg("num_words").alias("average_review_length"))
    reviews = reviews.drop("num_words")

    data = reviews.join(prices, ["asin"])
    data = data.drop("asin")
    data = data.repartition(20)

    xy = data.rdd.map(lambda row: (row.average_review_length, row.price))
    xy = xy.coalesce(8)
    x = xy.map(lambda v: v[0])
    y = xy.map(lambda v: v[1])
    n = x.count()

    sum_x = x.reduce(lambda a, b: a + b)
    sum_y = y.reduce(lambda a, b: a + b)

    sum_x2 = x.map(lambda x: x * x).reduce(lambda a, b: a + b)
    sum_y2 = y.map(lambda y: y * y).reduce(lambda a, b: a + b)

    sum_xy = xy.map(lambda v: v[0] * v[1]).reduce(lambda a, b: a + b)
    numerator = n* sum_xy - sum_x * sum_y
    denominator = ((n * sum_x2 - sum_x * sum_x) * (n * sum_y2 - sum_y * sum_y)) ** 0.5
    pearson = numerator / denominator if denominator != 0 else 0

    result = spark.createDataFrame([float(pearson)], FloatType())
    result.write.csv("hdfs:/output/pearson/result", header=False, mode="overwrite")

    data = xy.toDF(["x", "y"])
    data.write.json("hdfs:/output/pearson/data", mode="overwrite")

    spark.stop()
