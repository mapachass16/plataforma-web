import { ChangeDetectionStrategy, Component } from '@angular/core';
import { MatCardModule } from '@angular/material/card';
import { MatInputModule } from '@angular/material/input';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [MatCardModule, MatInputModule],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DashboardComponent {
  accounts: number = 50;
  users: number = 30;
  monitored: number = 20;
  devices: number = 10;
}
