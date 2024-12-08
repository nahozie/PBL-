Ekstraksi data SQL
WITH TrenLangganan AS (
    SELECT
        country AS Wilayah,
        operator AS Operator,
        SUM(revenue) AS Total_Pendapatan,
        COUNT(DISTINCT msisdn) AS Jumlah_Pelanggan,
        COUNT(DISTINCT CASE WHEN profile_status = 'active' THEN msisdn END) AS Jumlah_Pelanggan_Aktif,
        SUM(CASE WHEN profile_status = 'inactive' THEN 1 ELSE 0 END) AS Jumlah_Churn,
        (SUM(CASE WHEN profile_status = 'inactive' THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT msisdn)) AS Tingkat_Churn,
        (SUM(revenue) * 100.0 / SUM(SUM(revenue)) OVER ()) AS Tingkat_Pendapatan,
        (SUM(revenue) / NULLIF(COUNT(DISTINCT msisdn), 0)) AS ARPU
    FROM
        subs_cleaned
    GROUP BY
        country, operator
), 
ChurnRetensi AS (
    SELECT
        country AS Wilayah,
        operator AS Operator,
        cycle AS Siklus_Berlangganan,
        COUNT(DISTINCT msisdn) AS Jumlah_Pelanggan,
        SUM(CASE WHEN profile_status = 'inactive' THEN 1 ELSE 0 END) AS Jumlah_Churn,
        (SUM(CASE WHEN profile_status = 'inactive' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(DISTINCT msisdn), 0)) AS Tingkat_Churn,
        (100 - (SUM(CASE WHEN profile_status = 'inactive' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(DISTINCT msisdn), 0))) AS Tingkat_Retensi,
        (SUM(revenue) * 100.0 / SUM(SUM(revenue)) OVER ()) AS Tingkat_Pendapatan
    FROM
        subs_cleaned
    GROUP BY
        country, operator, cycle
),
KinerjaKampanye AS (
    SELECT
        adnet AS Kampanye,
        COUNT(*) AS Total_Upaya_Penagihan,
        SUM(CASE WHEN success_billing = 1 THEN 1 ELSE 0 END) AS Total_Sukses,
        (SUM(CASE WHEN success_billing = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS Tingkat_Keberhasilan
    FROM
        subs_cleaned
    GROUP BY
        adnet
)
SELECT
    tr.Wilayah,
    tr.Operator,
    tr.Total_Pendapatan,
    tr.Jumlah_Pelanggan,
    tr.Jumlah_Pelanggan_Aktif,
    tr.Jumlah_Churn,
    ROUND(tr.Tingkat_Churn, 2) || '%' AS Tingkat_Churn, 
    ROUND(cr.Tingkat_Retensi,2) || '%' AS Tingkat_Retensi_Cycle,
    ROUND(tr.Tingkat_Pendapatan, 2) || '%' AS Tingkat_Pendapatan,
    ROUND(tr.ARPU, 2) AS ARPU, 
    cr.Siklus_Berlangganan,
    cr.Jumlah_Pelanggan AS Jumlah_Pelanggan_Cycle,
    cr.Jumlah_Churn AS Jumlah_Churn_Cycle,
    ROUND(cr.Tingkat_Churn, 2) || '%' AS Tingkat_Churn_Cycle, 
    ROUND(cr.Tingkat_Pendapatan, 2) || '%' AS Tingkat_Pendapatan_Cycle, 
    kk.Kampanye,
    kk.Total_Upaya_Penagihan,
    kk.Total_Sukses,
    ROUND(kk.Tingkat_Keberhasilan, 2) || '%' AS Tingkat_Keberhasilan 
FROM
    TrenLangganan tr
LEFT JOIN
    ChurnRetensi cr ON tr.Wilayah = cr.Wilayah AND tr.Operator = cr.Operator
LEFT JOIN
    KinerjaKampanye kk ON 1 = 1;

    
    
--Validasi total pendapatan
SELECT
    country AS Wilayah,
    operator AS Operator,
    SUM(revenue) AS Total_Pendapatan_Validasi
FROM
    subs_cleaned
GROUP BY
    country, operator;

--Validasi ARPU
SELECT
    country AS Wilayah,
    operator AS Operator,
    SUM(revenue) / COUNT(DISTINCT msisdn) AS ARPU_Validasi
FROM
    subs_cleaned
GROUP BY
    country, operator;
    
--Validasi tingkat churn
SELECT
    country AS Wilayah,
    operator AS Operator,
    COUNT(DISTINCT msisdn) AS Total_Pelanggan,
    SUM(CASE WHEN profile_status = 'inactive' THEN 1 ELSE 0 END) AS Total_Churn,
    (SUM(CASE WHEN profile_status = 'inactive' THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT msisdn)) AS Tingkat_Churn_Validasi
FROM
    subs_cleaned
GROUP BY
    country, operator;

--validasi retensi
SELECT
    (COUNT(DISTINCT CASE WHEN profile_status = 'active' THEN msisdn END) * 100.0 / NULLIF(COUNT(DISTINCT msisdn), 0)) AS Tingkat_Retensi_Validasi
FROM
    subs_cleaned
WHERE
    country = 'ID' AND operator = 'Telkomsel';

--validasi kinerja kampanye
SELECT
    adnet AS Kampanye,
    COUNT(*) AS Total_Upaya_Penagihan_Validasi
FROM
    subs_cleaned
GROUP BY
    adnet;
    
-- Validasi Tingkat Keberhasilan Kampanye
SELECT
    adnet AS Kampanye,
    SUM(CASE WHEN success_billing = 1 THEN 1 ELSE 0 END) AS Total_Sukses,
    (SUM(CASE WHEN success_billing = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS Tingkat_Keberhasilan_Validasi
FROM
    subs_cleaned
GROUP BY
    adnet;
   
