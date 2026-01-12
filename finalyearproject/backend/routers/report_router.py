from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime
from config.database import get_db
from models.user import User, Report, ReportStatus
from schemas.user_schema import ReportCreate, ReportResponse, ReportUpdate
from middleware.auth_middleware import get_current_user, require_role

router = APIRouter(prefix="/reports", tags=["Reports"])


@router.post("/", response_model=ReportResponse, status_code=status.HTTP_201_CREATED)
async def create_report(
    report_data: ReportCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Submit a report against an advisor."""
    new_report = Report(
        reporter_id=current_user.id,
        reported_advisor_id=report_data.reported_advisor_id,
        reason=report_data.reason,
        description=report_data.description,
    )
    db.add(new_report)
    db.commit()
    db.refresh(new_report)
    return ReportResponse.model_validate(new_report)


@router.get("/my-reports", response_model=List[ReportResponse])
async def get_my_reports(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get reports filed by current user."""
    reports = db.query(Report).filter(Report.reporter_id == current_user.id).order_by(Report.created_at.desc()).all()
    return [ReportResponse.model_validate(r) for r in reports]


@router.get("/", response_model=List[ReportResponse])
async def get_all_reports(
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """Get all reports (Admin only)."""
    reports = db.query(Report).order_by(Report.created_at.desc()).all()
    return [ReportResponse.model_validate(r) for r in reports]


@router.put("/{report_id}", response_model=ReportResponse)
async def update_report(
    report_id: int,
    report_data: ReportUpdate,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """Update a report status and notes (Admin only)."""
    report = db.query(Report).filter(Report.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")

    if report_data.status is not None:
        report.status = ReportStatus(report_data.status)
        if report_data.status in ["resolved", "dismissed"]:
            report.resolved_at = datetime.utcnow()
    if report_data.admin_notes is not None:
        report.admin_notes = report_data.admin_notes

    db.commit()
    db.refresh(report)
    return ReportResponse.model_validate(report)
