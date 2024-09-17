import { ChangeDetectionStrategy, Component, AfterViewInit, ViewChildren, QueryList, ViewChild, OnInit } from '@angular/core';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatPaginator, MatPaginatorIntl, MatPaginatorModule } from '@angular/material/paginator';
import { MatSort, MatSortModule } from '@angular/material/sort';
import { MatTableDataSource, MatTableModule } from '@angular/material/table';
import { ActivatedRoute, Router } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatTooltipModule } from '@angular/material/tooltip';
import { CommonModule } from '@angular/common';
import { SupabaseService } from '../../../../services/supabase.service';

const MEDICALDEVICES = [
  {
    type: "Pulsera",
    status: "On",
    lastMeasurement: "150",
    lastMeasurementDate: new Date()
  },
  {
    type: "Glucometro",
    status: "Off",
    lastMeasurement: "20/10",
    lastMeasurementDate: new Date()
  },
  {
    type: "Collar",
    status: "Suspended",
    lastMeasurement: "210",
    lastMeasurementDate: new Date()
  },

];

const OPTIONS: string[] = [
  'On', 'Off', 'Suspended'
];

@Component({
  selector: 'app-see-tenant-dashboard',
  standalone: true,
  imports: [MatCardModule, MatInputModule, MatFormFieldModule, MatTableModule, MatSortModule, MatPaginatorModule, MatButtonModule, MatIconModule, MatTooltipModule, CommonModule],
  templateUrl: './see-tenant-dashboard.component.html',
  styleUrls: ['./see-tenant-dashboard.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SeeTenantDashboardComponent implements AfterViewInit, OnInit {
  id: any;
  user: any;
  users: any = [];
  monitored: any = [];
  IoTDevices: any = [];

  displayedUsersColumns: string[] = ['name', 'email', 'role', 'actions'];
  dataSourceUsers: MatTableDataSource<any>;

  displayedSeniorCitizensColumns: string[] = ['name', 'gender', 'age', 'actions'];
  dataSourceSeniorCitizens: MatTableDataSource<any>;

  displayedDevicesIoTColumns: string[] = ['name', 'status', 'serialID', 'actions'];
  dataSourceDevicesIoT: MatTableDataSource<any>;

  displayedMedicalDevicesColumns: string[] = ['type', 'status', 'lastMeasurement', 'lastMeasurementDate', 'actions'];
  dataSourceMedicalDevices: MatTableDataSource<any>;

  @ViewChild('usersPaginator') usersPaginator: MatPaginator;
  @ViewChild('usersSort') usersSort: MatSort;

  @ViewChild('seniorCitizensPaginator') seniorCitizensPaginator: MatPaginator;
  @ViewChild('seniorCitizensSort') seniorCitizensSort: MatSort;

  @ViewChild('devicesIoTPaginator') devicesIoTPaginator: MatPaginator;
  @ViewChild('devicesIoTSort') devicesIoTSort: MatSort;

  @ViewChild('medicalDevicesPaginator') medicalDevicesPaginator: MatPaginator;
  @ViewChild('medicalDevicesSort') medicalDevicesSort: MatSort;

  constructor(
    public _MatPaginatorIntl: MatPaginatorIntl,
    private _route: ActivatedRoute,
    private _supabaseService: SupabaseService,
  ) {
    this.dataSourceMedicalDevices = new MatTableDataSource(MEDICALDEVICES);
  }
  async ngOnInit() {
    this.user = await this._supabaseService.getUserSession();
    this.id = this._route.snapshot.paramMap.get('id');
    await this.getMembers(this.id, this.user.data.user.role);
    await this.getMonitored(this.id);
    await this.getIoTDevices(this.id);
  }


  ngAfterViewInit() {
    this.dataSourceMedicalDevices.paginator = this.medicalDevicesPaginator;
    this.dataSourceMedicalDevices.sort = this.medicalDevicesSort;
  }


  applyFilterUsers(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceUsers.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceUsers.paginator) {
      this.dataSourceUsers.paginator.firstPage();
    }
  }

  applyFilterSeniorCitizens(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceSeniorCitizens.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceSeniorCitizens.paginator) {
      this.dataSourceSeniorCitizens.paginator.firstPage();
    }
  }

  applyFilterDevicesIoT(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceDevicesIoT.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceDevicesIoT.paginator) {
      this.dataSourceDevicesIoT.paginator.firstPage();
    }
  }

  applyFilterMedicalDevices(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceMedicalDevices.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceMedicalDevices.paginator) {
      this.dataSourceMedicalDevices.paginator.firstPage();
    }
  }

  async getMembers(tenant_id: any, role: string) {
    try {
      if (role === "service_role") {
        const { data, error } = await this._supabaseService.getTenantMembersService(tenant_id);
        if (error) {
          throw new Error(`Error al obtener los miembros del tenant (service_role): ${error.message}`);
        }
        for (let i = 0; i < data.length; i++) {
          const member = data[i];
          const newMember = {
            name: member.firstname + ' ' + member.lastname,
            email: member.email,
            role: member.tenant_role,
          };
          this.users.push(newMember);
        }
      } else {
        const { data, error } = await this._supabaseService.getTenantMembers(tenant_id);
        if (error) {
          throw new Error(`Error al obtener los miembros del tenant: ${error.message}`);
        }
        for (let i = 0; i < data.length; i++) {
          const member = data[i];
          const newMember = {
            name: member.firstname + ' ' + member.lastname,
            email: member.email,
            role: member.tenant_role,
          };
          this.users.push(newMember);
        }

      }
      this.dataSourceUsers = new MatTableDataSource(this.users);
      this.dataSourceUsers.paginator = this.usersPaginator;
      this.dataSourceUsers.sort = this.usersSort;
      this.usersPaginator._intl.itemsPerPageLabel = 'Usuarios por página';

    } catch (error: any) {
      console.error('Error en getMembers:', error.message || error);
    }
  }

  async getMonitored(tenant_id: any) {
    try {
      const { data, error } = await this._supabaseService.getMonitoredPeople(tenant_id);
      if (error) {
        throw new Error(`Error al obtener los monitoreados del tenant ${error.message}`);
      }
      for (let i = 0; i < data.length; i++) {
        const monitored = data[i];
        const newMonitored = {
          name: monitored.first_name + ' ' + monitored.last_name,
          gender: (monitored.gender == "M") ? "Masculino" : "Femenino",
          age: monitored?.age ?? "No tiene dato",
        };
        this.monitored.push(newMonitored);
      }
      this.dataSourceSeniorCitizens = new MatTableDataSource(this.monitored);
      this.dataSourceSeniorCitizens.paginator = this.seniorCitizensPaginator;
      this.dataSourceSeniorCitizens.sort = this.seniorCitizensSort;
      this.seniorCitizensPaginator._intl.itemsPerPageLabel = 'Monitoreados por página';

    } catch (error: any) {
      console.error('Error en getMonitored:', error.message || error);
    }
  }

  async getIoTDevices(tenant_id: any) {
    try {
      const { data, error } = await this._supabaseService.getIoTDevicesByTenant(tenant_id);
      if (error) {
        throw new Error(`Error al obtener los dispositivos IoT del tenant ${error.message}`);
      }
      for (let i = 0; i < data.length; i++) {
        const IoTDevice = data[i];
        const newIoTDevice = {
          name: IoTDevice.name,
          status: OPTIONS[Math.floor(Math.random() * OPTIONS.length)],
          serialID: IoTDevice.serial_number,
        };
        this.IoTDevices.push(newIoTDevice);
      }
      this.dataSourceDevicesIoT = new MatTableDataSource(this.IoTDevices);
      this.dataSourceDevicesIoT.paginator = this.devicesIoTPaginator;
      this.dataSourceDevicesIoT.sort = this.devicesIoTSort;
      this.devicesIoTPaginator._intl.itemsPerPageLabel = 'Dispositivos IoT por página';

    } catch (error: any) {
      console.error('Error en getMonitored:', error.message || error);
    }
  }
}