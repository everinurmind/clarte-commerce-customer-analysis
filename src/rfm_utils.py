"""
RFM utility functions for Clarté Commerce analysis.
"""

import pandas as pd
import numpy as np


def calculate_rfm(transactions, snapshot_date):
    """
    Calculate RFM values per customer.
    
    Parameters
    ----------
    transactions : pd.DataFrame
        Transaction data with customer_id, transaction_date, total_amount
    snapshot_date : pd.Timestamp
        Reference date for recency calculation
        
    Returns
    -------
    pd.DataFrame with customer_id, recency, frequency, monetary
    """
    rfm = transactions.groupby('customer_id').agg(
        recency=('transaction_date', 'max'),  # days since last purchase
        frequency=('transaction_id', 'nunique'),
        monetary=('total_amount', 'sum')
    ).reset_index()
    
    rfm['recency'] = (snapshot_date - rfm['recency']).dt.days
    rfm['monetary'] = rfm['monetary'].round(2)
    
    return rfm


def assign_rfm_labels(rfm):
    """
    Assign human-readable segment labels based on RFM scores.
    
    Expects columns: r_score, f_score, m_score
    """
    conditions = [
        (rfm['r_score'] >= 4) & (rfm['f_score'] >= 4) & (rfm['m_score'] >= 4),
        (rfm['r_score'] >= 3) & (rfm['f_score'] >= 3) & (rfm['m_score'] >= 3),
        (rfm['r_score'] >= 4) & (rfm['f_score'] <= 2),
        (rfm['r_score'] >= 3) & (rfm['f_score'] >= 1) & (rfm['m_score'] >= 2),
        (rfm['r_score'] <= 2) & (rfm['f_score'] >= 3) & (rfm['m_score'] >= 3),
        (rfm['r_score'] <= 2) & (rfm['f_score'] >= 4) & (rfm['m_score'] >= 4),
        (rfm['r_score'] <= 2) & (rfm['f_score'] <= 2),
    ]
    
    labels = [
        'Champions',
        'Loyal Customers',
        'New Customers',
        'Potential Loyalists',
        'At Risk',
        'Cant Lose Them',
        'Lost'
    ]
    
    rfm['rfm_label'] = np.select(conditions, labels, default='Other')
    
    return rfm