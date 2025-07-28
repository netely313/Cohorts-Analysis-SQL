--Create weekly cohorts, as start of activity, and last week of activity
WITH cohort_data AS (
    SELECT
        user_pseudo_id,

        --cohorts, first week of activity
        DATE_TRUNC(subscription_start, WEEK) AS cohort_start_week,

        --last week of activity
        DATE_TRUNC(subscription_end, WEEK) AS end_week

    FROM
        `subscriptions`
),


--Counting of the number of users who churn for 6 weeks after they started their subscription
weekly_churn AS (
    SELECT
        cohort_start_week,

        --Determine how many weeks have passed since the subscription started (cohort_start _week)
        --until their last activity (end _week)
        DATE_DIFF(end_week, cohort_start_week, WEEK) AS week_number,

        COUNT(DISTINCT user_pseudo_id) AS active_users

    FROM
        cohort_data

        --Only consider users who have information about the last active week
    WHERE
        end_week IS NOT NULL

        --Select six weeks of activity duration after subscription starts (cohort_start _week)
        AND DATE_DIFF(end_week, cohort_start_week, WEEK) BETWEEN 0 AND 6

        --Create groups of users who started their subscription in the same week
    GROUP BY
        cohort_start_week, week_number
)

--Summarize and determine the number of churn users for each week separately (from week_0 to week_6), creating columns for each week of activity
SELECT
   cohort_start_week,
   SUM(CASE WHEN week_number = 0 THEN active_users ELSE 0 END) AS week_0,
   SUM(CASE WHEN week_number = 1 THEN active_users ELSE 0 END) AS week_1,
   SUM(CASE WHEN week_number = 2 THEN active_users ELSE 0 END) AS week_2,
   SUM(CASE WHEN week_number = 3 THEN active_users ELSE 0 END) AS week_3,
   SUM(CASE WHEN week_number = 4 THEN active_users ELSE 0 END) AS week_4,
   SUM(CASE WHEN week_number = 5 THEN active_users ELSE 0 END) AS week_5,
   SUM(CASE WHEN week_number = 6 THEN active_users ELSE 0 END) AS week_6,

FROM
   weekly_churn
GROUP BY
   cohort_start_week
ORDER BY
   cohort_start_week;

