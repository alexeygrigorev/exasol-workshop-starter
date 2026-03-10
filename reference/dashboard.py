"""
Streamlit dashboard for warehouse health checks.

Usage:
    uv run streamlit run dashboard.py
"""

import altair as alt
import pandas as pd
import streamlit as st
from streamlit_autorefresh import st_autorefresh
from datetime import datetime

import utils.db as db


@st.cache_resource
def get_connection():
    conn = db.connect()
    db.ensure_schemas(conn)
    return conn


def load_row_counts(conn) -> pd.DataFrame:
    query = f"""
        SELECT 'PRACTICE' AS TABLE_NAME, COUNT(*) AS ROW_COUNT
        FROM {db.WAREHOUSE_SCHEMA}.PRACTICE
        UNION ALL
        SELECT 'CHEMICAL' AS TABLE_NAME, COUNT(*) AS ROW_COUNT
        FROM {db.WAREHOUSE_SCHEMA}.CHEMICAL
        UNION ALL
        SELECT 'PRESCRIPTION' AS TABLE_NAME, COUNT(*) AS ROW_COUNT
        FROM {db.WAREHOUSE_SCHEMA}.PRESCRIPTION
    """
    rows = conn.execute(query).fetchall()
    df = pd.DataFrame(rows, columns=["TABLE_NAME", "ROW_COUNT"])
    if not df.empty:
        df["ROW_COUNT"] = pd.to_numeric(df["ROW_COUNT"], errors="coerce").fillna(0).astype(int)
    return df


def load_top_drugs(conn) -> pd.DataFrame:
    rows = conn.execute(f"""
        SELECT sub.BNF_CODE, c.CHEMICAL_NAME, sub.TOTAL_ITEMS, sub.TOTAL_COST
        FROM (
            SELECT BNF_CODE, CHEMICAL_CODE, SUM(ITEMS) AS TOTAL_ITEMS, SUM(ACTUAL_COST) AS TOTAL_COST
            FROM {db.WAREHOUSE_SCHEMA}.PRESCRIPTION
            GROUP BY BNF_CODE, CHEMICAL_CODE
        ) sub
        LEFT JOIN {db.WAREHOUSE_SCHEMA}.CHEMICAL c
            ON sub.CHEMICAL_CODE = c.CHEMICAL_CODE
        ORDER BY sub.TOTAL_COST DESC
        LIMIT 10
    """).fetchall()

    df = pd.DataFrame(rows, columns=["BNF_CODE", "CHEMICAL_NAME", "TOTAL_ITEMS", "TOTAL_COST"])
    if not df.empty:
        df["CHEMICAL_NAME"] = df["CHEMICAL_NAME"].fillna("N/A")
        df["TOTAL_ITEMS"] = pd.to_numeric(df["TOTAL_ITEMS"], errors="coerce").fillna(0).astype(int)
        df["TOTAL_COST"] = pd.to_numeric(df["TOTAL_COST"], errors="coerce").fillna(0.0)
    return df


def load_top_practices(conn) -> pd.DataFrame:
    rows = conn.execute(f"""
        SELECT sub.PRACTICE_CODE, pr.PRACTICE_NAME, pr.POSTCODE, sub.TOTAL_ITEMS
        FROM (
            SELECT PRACTICE_CODE, SUM(ITEMS) AS TOTAL_ITEMS
            FROM {db.WAREHOUSE_SCHEMA}.PRESCRIPTION
            GROUP BY PRACTICE_CODE
        ) sub
        LEFT JOIN {db.WAREHOUSE_SCHEMA}.PRACTICE pr
            ON sub.PRACTICE_CODE = pr.PRACTICE_CODE
        ORDER BY sub.TOTAL_ITEMS DESC
        LIMIT 10
    """).fetchall()

    df = pd.DataFrame(rows, columns=["PRACTICE_CODE", "PRACTICE_NAME", "POSTCODE", "TOTAL_ITEMS"])
    if not df.empty:
        df[["PRACTICE_NAME", "POSTCODE"]] = df[["PRACTICE_NAME", "POSTCODE"]].fillna("N/A")
        df["TOTAL_ITEMS"] = pd.to_numeric(df["TOTAL_ITEMS"], errors="coerce").fillna(0).astype(int)
    return df


def render_compact_bar_chart(df: pd.DataFrame, x_col: str, y_col: str) -> None:
    chart_height = max(310, min(530, 33 * len(df) + 50))
    chart = (
        alt.Chart(df)
        .mark_bar()
        .encode(
            x=alt.X(f"{x_col}:N", sort=alt.SortField(field=y_col, order="descending"), axis=alt.Axis(labels=False, ticks=False, domain=False, title=None)),
            y=alt.Y(f"{y_col}:Q", title=None),
            tooltip=[alt.Tooltip(f"{x_col}:N", title=x_col), alt.Tooltip(f"{y_col}:Q", title=y_col, format=",.2f")],
        )
        .properties(height=chart_height)
    )
    st.altair_chart(chart, use_container_width=True)


def main() -> None:
    st.set_page_config(page_title="NHS Prescriptions Dashboard", layout="wide")
    st.title("NHS Prescriptions Dashboard")

    st_autorefresh(interval=5000, key="dashboard_autorefresh")

    try:
        conn = get_connection()
    except Exception as error:
        st.error(f"Database connection failed: {error}")
        st.stop()

    controls_col, refresh_time_col = st.columns([1, 4])
    with controls_col:
        if st.button("Refresh data"):
            st.cache_data.clear()
    with refresh_time_col:
        st.caption(f"Last refresh: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

    row_counts = load_row_counts(conn)
    top_drugs = load_top_drugs(conn)
    top_practices = load_top_practices(conn)

    st.subheader("Row counts")
    c1, c2, c3 = st.columns(3)
    counts = {r["TABLE_NAME"]: int(r["ROW_COUNT"]) for _, r in row_counts.iterrows()}
    c1.metric("PRACTICE", f"{counts.get('PRACTICE', 0):,}")
    c2.metric("CHEMICAL", f"{counts.get('CHEMICAL', 0):,}")
    c3.metric("PRESCRIPTION", f"{counts.get('PRESCRIPTION', 0):,}")

    st.subheader("Top 10 drugs by total cost")
    drugs_table_col, drugs_chart_col = st.columns(2)
    with drugs_table_col:
        st.dataframe(
            top_drugs,
            use_container_width=True,
            hide_index=True,
            column_config={
                "TOTAL_ITEMS": st.column_config.NumberColumn("TOTAL_ITEMS", format="%,d"),
                "TOTAL_COST": st.column_config.NumberColumn("TOTAL_COST", format="£%.2f"),
            },
        )
    with drugs_chart_col:
        if not top_drugs.empty:
            render_compact_bar_chart(top_drugs, "BNF_CODE", "TOTAL_COST")

    st.subheader("Top 10 practices by prescription volume")
    practices_table_col, practices_chart_col = st.columns(2)
    with practices_table_col:
        st.dataframe(
            top_practices,
            use_container_width=True,
            hide_index=True,
            column_config={
                "TOTAL_ITEMS": st.column_config.NumberColumn("TOTAL_ITEMS", format="%,d"),
            },
        )
    with practices_chart_col:
        if not top_practices.empty:
            render_compact_bar_chart(top_practices, "PRACTICE_CODE", "TOTAL_ITEMS")


if __name__ == "__main__":
    main()
