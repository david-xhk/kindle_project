from pyspark.sql import SparkSession
from pyspark.ml.feature import RegexTokenizer, CountVectorizer, IDF
from pyspark.sql.functions import udf, col
from pyspark.sql.types import StructType, StructField, ArrayType, MapType, StringType, IntegerType, FloatType
# from nltk import word_tokenize

if __name__ == "__main__":
    spark = SparkSession.builder.appName("Calculate TF-IDF of review texts").getOrCreate()

    df = spark.read.csv(
        path   = "hdfs:/input/review_texts.csv",
        header = False,
        escape = "\"",
        schema = StructType([StructField("reviewId", IntegerType(), True),
                             StructField("asin", StringType(), True),
                             StructField("reviewText", StringType(), True)]))
    df = df.drop("asin")
    df = df.repartition(20)

    # # Use nltk.word_tokenizer to tokenize words
    # @udf(ArrayType(StringType()))
    # def tokenize(string):
    #     return word_tokenize(string)

    # df = df.withColumn("words", tokenize("reviewText"))

    df = RegexTokenizer(inputCol="reviewText", outputCol="words", pattern="\\W").transform(df)
    df = df.drop("reviewText")

    cv_model = CountVectorizer(inputCol="words", outputCol="tf").fit(df)
    vocabulary = cv_model.vocabulary

    df = cv_model.transform(df)
    df = df.drop("words")
    df.cache()

    df = IDF(inputCol="tf", outputCol="tfidf").fit(df).transform(df)
    df = df.drop("tf")
    df.unpersist()

    @udf(MapType(StringType(), FloatType()))
    def create_map(vector):
        zipped = zip(vector.indices, vector.values)
        return dict((vocabulary[int(x)], float(y)) for (x, y) in zipped)

    results = df.withColumn("tfidf", create_map("tfidf"))

    results.write.json("hdfs:/output/tfidf", mode="overwrite")

    spark.stop()
