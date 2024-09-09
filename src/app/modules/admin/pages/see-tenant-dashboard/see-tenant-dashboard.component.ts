import { ChangeDetectionStrategy, Component, AfterViewInit, ViewChildren, QueryList, ViewChild } from '@angular/core';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatPaginator, MatPaginatorIntl, MatPaginatorModule } from '@angular/material/paginator';
import { MatSort, MatSortModule } from '@angular/material/sort';
import { MatTableDataSource, MatTableModule } from '@angular/material/table';
import { Router } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatTooltipModule } from '@angular/material/tooltip';
import { CommonModule } from '@angular/common';

const USERS = [
  {
    name: "Paula Chaves",
    email: "p.chaves@example.com",
    role: "Owner"
  },
  {
    name: "Carlos Mendoza",
    email: "c.mendoza@example.com",
    role: "User"
  },
  {
    name: "Laura Gómez",
    email: "l.gomez@example.com",
    role: "User"
  },
  {
    name: "Juan Pérez",
    email: "j.perez@example.com",
    role: "User"
  },
  {
    name: "Ana Martínez",
    email: "a.martinez@example.com",
    role: "User"
  }
];

const SENIORCITIZENS = [
  {
    name: "Alberto Campos",
    gender: "Masculino",
    age: "74"
  },
  {
    name: "Carmen Rojas",
    gender: "Femenino",
    age: "70"
  },
  {
    name: "Luis Fonseca",
    gender: "Masculino",
    age: "67"
  }
];

const DEVICESIOT = [
  {
    name: "Cuarto 1",
    status: "On",
    serialID: "744564651"
  },
  {
    name: "Sala",
    status: "Off",
    serialID: "456478415"
  },
  {
    name: "Cocina",
    status: "Suspended",
    serialID: "759841235"
  },
  {
    name: "Baño",
    status: "On",
    serialID: "984127836"
  },
  {
    name: "Cuarto 2",
    status: "On",
    serialID: "671489657"
  }
];

@Component({
  selector: 'app-see-tenant-dashboard',
  standalone: true,
  imports: [MatCardModule, MatInputModule, MatFormFieldModule, MatTableModule, MatSortModule, MatPaginatorModule, MatButtonModule, MatIconModule, MatTooltipModule, CommonModule],
  templateUrl: './see-tenant-dashboard.component.html',
  styleUrls: ['./see-tenant-dashboard.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SeeTenantDashboardComponent implements AfterViewInit {
  displayedUsersColumns: string[] = ['name', 'email', 'role', 'actions'];
  dataSourceUsers: MatTableDataSource<any>;

  displayedSeniorCitizensColumns: string[] = ['name', 'gender', 'age', 'actions'];
  dataSourceSeniorCitizens: MatTableDataSource<any>;

  displayedDevicesIoTColumns: string[] = ['name', 'status', 'serialID', 'actions'];
  dataSourceDevicesIoT: MatTableDataSource<any>;

  @ViewChild('usersPaginator') usersPaginator: MatPaginator;
  @ViewChild('usersSort') usersSort: MatSort;

  @ViewChild('seniorCitizensPaginator') seniorCitizensPaginator: MatPaginator;
  @ViewChild('seniorCitizensSort') seniorCitizensSort: MatSort;

  @ViewChild('devicesIoTPaginator') devicesIoTPaginator: MatPaginator;
  @ViewChild('devicesIoTSort') devicesIoTSort: MatSort;

  constructor(
    private _router: Router,
    public _MatPaginatorIntl: MatPaginatorIntl,
  ) {
    this.dataSourceUsers = new MatTableDataSource(USERS);
    this.dataSourceSeniorCitizens = new MatTableDataSource(SENIORCITIZENS);
    this.dataSourceDevicesIoT = new MatTableDataSource(DEVICESIOT);
  }

  ngAfterViewInit() {
    this.dataSourceUsers.paginator = this.usersPaginator;
    this.dataSourceUsers.sort = this.usersSort;

    this.dataSourceSeniorCitizens.paginator = this.seniorCitizensPaginator;
    this.dataSourceSeniorCitizens.sort = this.seniorCitizensSort;

    this.dataSourceDevicesIoT.paginator = this.devicesIoTPaginator;
    this.dataSourceDevicesIoT.sort = this.devicesIoTSort;

    this.usersPaginator._intl.itemsPerPageLabel = 'Datos por página';


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
}