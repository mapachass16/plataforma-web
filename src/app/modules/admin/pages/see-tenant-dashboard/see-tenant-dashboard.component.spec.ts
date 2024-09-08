import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SeeTenantDashboardComponent } from './see-tenant-dashboard.component';

describe('SeeTenantDashboardComponent', () => {
  let component: SeeTenantDashboardComponent;
  let fixture: ComponentFixture<SeeTenantDashboardComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SeeTenantDashboardComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(SeeTenantDashboardComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
