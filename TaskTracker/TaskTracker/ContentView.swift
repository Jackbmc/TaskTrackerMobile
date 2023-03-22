import SwiftUI
import UserNotifications

struct ContentView: View {
    @State private var tasks = [Task]()
    @State private var newTaskTitle = ""
    @State private var newTaskDueDate = Date()
    @State private var isEditing = false
    @State private var editingTask: Task?
    
    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: "tasks"),
           let storedTasks = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = storedTasks
        }
    }
    
    private func saveTasks() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: "tasks")
        }
    }
    
    private func addTask() {
        let newTask = Task(title: newTaskTitle, isCompleted: false, dueDate: newTaskDueDate)
        tasks.append(newTask)
        saveTasks()
        scheduleNotification(for: newTask) // Schedule a notification for the new task
        newTaskTitle = ""
    }
    
    private func toggleTaskCompletion(task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            saveTasks()
        }
    }
    
    private func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
        saveTasks()
    }
    
    private func clearAllTasks() {
        tasks.removeAll()
        saveTasks()
    }
    
    private func startEditing(task: Task) {
        editingTask = task
        newTaskTitle = task.title
        newTaskDueDate = task.dueDate ?? Date() // Set the due date picker to the task's due date
        isEditing = true
    }
    
    private func updateTask() {
        if let task = editingTask,
           let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].title = newTaskTitle
            tasks[index].dueDate = newTaskDueDate
            saveTasks()
            isEditing = false
            newTaskTitle = ""
            editingTask = nil
            scheduleNotification(for: tasks[index]) // Schedule a notification for the updated task
        }
    }
    
    private func cancelEditing() {
        isEditing = false
        newTaskTitle = ""
        editingTask = nil
    }
    
    private func isTaskOverdue(task: Task) -> Bool {
        guard let dueDate = task.dueDate else { return false }
        return Date() > dueDate
    }
    
    private func sortedTasks() -> [Task] {
        return tasks.sorted(by: { (task1, task2) -> Bool in
            if let dueDate1 = task1.dueDate, let dueDate2 = task2.dueDate {
                return dueDate1 < dueDate2
            } else if task1.dueDate != nil {
                return true
            } else {
                return false
            }
        })
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            if granted {
                print("Notification permissions granted")
            } else {
                print("Notification permissions not granted")
            }
        }
    }
    
    private func scheduleNotification(for task: Task) {
        guard let dueDate = task.dueDate else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "\(task.title) is due!"
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Notification scheduled for task: \(task.title)")
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField(isEditing ? "Edit task..." : "Enter a new task...", text: $newTaskTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: isEditing ? updateTask : addTask) {
                        Image(systemName: isEditing ? "pencil.circle.fill" : "arrow.up.circle.fill")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.blue)
                    }
                    .disabled(newTaskTitle.isEmpty)
                }
                .padding()
                
                HStack {
                    Text("Due date/time:")
                    DatePicker("", selection: $newTaskDueDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                }
                .padding()
                
                List {
                    ForEach(sortedTasks()) { task in
                        HStack {
                            Button(action: {
                                toggleTaskCompletion(task: task)
                            }) {
                                Image(systemName: task.isCompleted ? "checkmark.square" : "square")
                            }
                            VStack(alignment: .leading) {
                                Text(task.title)
                                    .strikethrough(task.isCompleted, color: .red)
                                    .onTapGesture {
                                        toggleTaskCompletion(task: task)
                                    }
                                    .onLongPressGesture {
                                        startEditing(task: task)
                                    }
                                if let dueDate = task.dueDate {
                                    Text(formatter.string(from: dueDate))
                                        .font(.footnote)
                                        .foregroundColor(isTaskOverdue(task: task) ? Color(#colorLiteral(red: 1, green: 0, blue: 0.6392156863, alpha: 1)) : Color.secondary)
                                }
                            }
                        }
                        .padding()
                    }
                    .onDelete(perform: deleteTask)
                }
            }
            .onAppear {
                loadTasks()
                requestNotificationPermissions()
            }
            .navigationTitle("TaskTracker")
            .navigationBarItems(leading: isEditing ? Button(action: cancelEditing) {
                Text("Cancel")
            } : nil, trailing: Button(action: clearAllTasks) {
                Text("Clear All")
            })
        }
    }
    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
    
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}
